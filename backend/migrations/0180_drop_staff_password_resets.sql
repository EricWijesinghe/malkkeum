-- Token-based staff password resets are replaced by the SMS code flow (0179). Unused tokens expire in 30 minutes.
DROP TABLE staff_password_resets;
