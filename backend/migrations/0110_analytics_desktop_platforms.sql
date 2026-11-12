-- Desktop builds label their analytics events 'windows' / 'macos' (0071 allowed android/ios/web only).
-- The new CHECK is added NOT VALID (no full scan under the write lock), then VALIDATEd; the old one is dropped in between.
ALTER TABLE analytics_events
    ADD CONSTRAINT analytics_events_platform_allowed CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos')) NOT VALID;
ALTER TABLE analytics_events DROP CONSTRAINT IF EXISTS analytics_events_platform_check;
ALTER TABLE analytics_events VALIDATE CONSTRAINT analytics_events_platform_allowed;
