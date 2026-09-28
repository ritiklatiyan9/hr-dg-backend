-- Keep an expired duty and its evidence reviewable while allowing a new day
-- to begin. No effective exit time is invented by this transition.
ALTER TABLE app.duty_sessions DROP CONSTRAINT duty_sessions_status_check;
ALTER TABLE app.duty_sessions ADD CONSTRAINT duty_sessions_status_check
  CHECK (status IN ('open', 'closed', 'needs_review'));

CREATE INDEX event_verifications_pending_review
  ON app.event_verifications(organization_id,site_id,event_id)
  WHERE status='pending_verification';
