-- ============================================
-- FYNA - Finance AI Application
-- Migration V16: Create Notifications Table
-- ============================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    type VARCHAR(30) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    metadata JSONB,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_pushed BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_notifications_type CHECK (type IN (
        'BUDGET_ALERT', 'GOAL_PROGRESS', 'GOAL_COMPLETED', 
        'BILL_REMINDER', 'RECURRING_TRANSACTION', 'AI_INSIGHT',
        'SPENDING_ANOMALY', 'INVESTMENT_RECOMMENDATION', 
        'WEEKLY_SUMMARY', 'SYSTEM', 'SECURITY'
    ))
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_type ON notifications (type);
CREATE INDEX idx_notifications_is_read ON notifications (is_read);
CREATE INDEX idx_notifications_created_at ON notifications (created_at);
CREATE INDEX idx_notifications_scheduled_for ON notifications (scheduled_for);

-- Composite index for unread notifications query
CREATE INDEX idx_notifications_user_unread ON notifications (user_id, is_read, created_at DESC);

-- Comments
COMMENT ON TABLE notifications IS 'Stores user notifications and alerts';
COMMENT ON COLUMN notifications.type IS 'Notification type: BUDGET_ALERT, GOAL_PROGRESS, BILL_REMINDER, etc.';
COMMENT ON COLUMN notifications.action_url IS 'Deep link URL for notification action';
COMMENT ON COLUMN notifications.scheduled_for IS 'When the notification should be delivered (for scheduled notifications)';
COMMENT ON COLUMN notifications.is_pushed IS 'Whether push notification was sent';
