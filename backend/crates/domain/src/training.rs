//! Partner onboarding training: a module is complete when every checklist item is ticked and its quiz
//! is passed. A partner receives jobs only after every required module is complete.

use crate::DomainError;

/// Minimum quiz score (percent) to pass a module.
pub const PASS_PERCENT: u32 = 80;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct QuizQuestion {
    /// Zero-based index of the correct option.
    pub correct: u8,
    pub option_count: u8,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct QuizResult {
    pub correct: u32,
    pub total: u32,
    pub passed: bool,
}

/// Grades one attempt. `answers[i]` is the chosen option for `questions[i]`.
/// An empty quiz passes trivially; malformed answers are rejected, not counted as wrong.
pub fn grade_quiz(questions: &[QuizQuestion], answers: &[u8]) -> Result<QuizResult, DomainError> {
    if answers.len() != questions.len() {
        return Err(DomainError::OutOfRange("quiz_answers"));
    }
    let mut correct = 0_u32;
    for (q, &a) in questions.iter().zip(answers) {
        if q.option_count == 0 || a >= q.option_count {
            return Err(DomainError::OutOfRange("quiz_answer"));
        }
        if a == q.correct {
            correct += 1;
        }
    }
    let total = u32::try_from(questions.len()).map_err(|_| DomainError::OutOfRange("quiz_questions"))?;
    let passed = correct * 100 >= total * PASS_PERCENT;
    Ok(QuizResult { correct, total, passed })
}

/// A module is complete when all checklist items are ticked and the quiz is passed.
pub fn module_complete(checklist_total: usize, checklist_ticked: usize, quiz_passed: bool) -> bool {
    checklist_ticked >= checklist_total && quiz_passed
}

/// Job offers require every required module to be complete.
pub fn check_can_receive_jobs(required_modules_complete: &[bool]) -> Result<(), DomainError> {
    if required_modules_complete.iter().all(|&done| done) {
        Ok(())
    } else {
        Err(DomainError::TrainingIncomplete)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn q(correct: u8) -> QuizQuestion {
        QuizQuestion { correct, option_count: 4 }
    }

    #[test]
    fn grades_correct_answers() {
        let qs = [q(0), q(2), q(1), q(3), q(0)];
        let r = grade_quiz(&qs, &[0, 2, 1, 3, 0]).unwrap();
        assert_eq!((r.correct, r.total, r.passed), (5, 5, true));
    }

    #[test]
    fn eighty_percent_passes_and_below_fails() {
        let qs = [q(0), q(0), q(0), q(0), q(0)];
        assert!(grade_quiz(&qs, &[0, 0, 0, 0, 1]).unwrap().passed, "4/5 = 80% passes");
        assert!(!grade_quiz(&qs, &[0, 0, 0, 1, 1]).unwrap().passed, "3/5 = 60% fails");
    }

    #[test]
    fn length_mismatch_and_out_of_range_answers_are_errors() {
        let qs = [q(0), q(0)];
        assert!(grade_quiz(&qs, &[0]).is_err());
        assert!(grade_quiz(&qs, &[0, 4]).is_err());
        let zero_options = [QuizQuestion { correct: 0, option_count: 0 }];
        assert!(grade_quiz(&zero_options, &[0]).is_err());
    }

    #[test]
    fn empty_quiz_passes() {
        assert!(grade_quiz(&[], &[]).unwrap().passed);
    }

    #[test]
    fn module_needs_full_checklist_and_passing_quiz() {
        assert!(module_complete(3, 3, true));
        assert!(!module_complete(3, 2, true));
        assert!(!module_complete(3, 3, false));
    }

    #[test]
    fn jobs_blocked_until_all_required_modules_complete() {
        assert!(check_can_receive_jobs(&[true, true]).is_ok());
        assert_eq!(check_can_receive_jobs(&[true, false]), Err(DomainError::TrainingIncomplete));
        assert!(check_can_receive_jobs(&[]).is_ok(), "no required modules configured");
    }
}
