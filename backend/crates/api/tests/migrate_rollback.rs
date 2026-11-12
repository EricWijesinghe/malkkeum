//! Rollback safety: the previous image must start against a database a newer release already migrated.

use sqlx::{PgPool, migrate::MigrateError};

/// A version no shipped migration uses; stands for a migration added by a newer release.
const FUTURE_VERSION: i64 = 999_999;

#[sqlx::test(migrations = "../../migrations")]
async fn migrator_tolerates_a_migration_from_a_newer_release(db: PgPool) {
    sqlx::query(
        "INSERT INTO _sqlx_migrations (version, description, success, checksum, execution_time)
         VALUES ($1, 'from a newer release', TRUE, decode('00', 'hex'), 0)",
    )
    .bind(FUTURE_VERSION)
    .execute(&db)
    .await
    .expect("insert future migration row");

    // The default migrator refuses to run: this is what broke rollbacks.
    let strict = sqlx::migrate!("../../migrations").run(&db).await;
    assert!(matches!(strict, Err(MigrateError::VersionMissing(FUTURE_VERSION))), "{strict:?}");

    api::migrate(&db).await.expect("startup migrator ignores the unknown row");
    assert!(api::lifecycle::migrations_applied(&db).await, "readiness still passes");
    let kept: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM _sqlx_migrations WHERE version = $1)")
        .bind(FUTURE_VERSION)
        .fetch_one(&db)
        .await
        .expect("read back");
    assert!(kept, "the newer release's row is left alone");
}
