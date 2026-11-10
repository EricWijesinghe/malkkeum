-- Team member logins (partner app). Members sign in with their invited phone; the
-- session subject is team_members.id and refresh_tokens.role = 'member' (free text, no change needed).
ALTER TABLE team_members ADD COLUMN last_login_at TIMESTAMPTZ;
CREATE INDEX team_members_phone_idx ON team_members (phone);
