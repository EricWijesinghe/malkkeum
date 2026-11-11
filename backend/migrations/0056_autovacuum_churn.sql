-- Autovacuum for high-churn tables. The server-wide defaults (deploy/docker-compose.yml) scale by 5% of
-- the table, which lets short-lived rows (OTP codes, sessions, failure logs) bloat between passes.
-- These tables vacuum after a fixed number of dead rows instead.
ALTER TABLE otp_codes SET (autovacuum_vacuum_scale_factor = 0, autovacuum_vacuum_threshold = 200,
    autovacuum_analyze_scale_factor = 0, autovacuum_analyze_threshold = 200);
ALTER TABLE refresh_tokens SET (autovacuum_vacuum_scale_factor = 0, autovacuum_vacuum_threshold = 500,
    autovacuum_analyze_scale_factor = 0, autovacuum_analyze_threshold = 500);
ALTER TABLE ops_failures SET (autovacuum_vacuum_scale_factor = 0, autovacuum_vacuum_threshold = 500);
ALTER TABLE ops_http_errors SET (autovacuum_vacuum_scale_factor = 0, autovacuum_vacuum_threshold = 100);
ALTER TABLE notifications SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_analyze_scale_factor = 0.01);
