-- ============================================
-- FYNA - Finance AI Application
-- Migration V9: Create AI Classifications Table
-- ============================================

CREATE TABLE ai_classifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL,
    suggested_category_id UUID,
    confirmed_category_id UUID,
    confidence_score DECIMAL(5, 4) NOT NULL,
    original_text VARCHAR(500) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    was_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    was_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    feature_vector JSONB,
    classified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT fk_ai_classifications_transaction FOREIGN KEY (transaction_id) 
        REFERENCES transactions(id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_classifications_suggested_category FOREIGN KEY (suggested_category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_ai_classifications_confirmed_category FOREIGN KEY (confirmed_category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT chk_ai_classifications_confidence CHECK (confidence_score BETWEEN 0 AND 1)
);

-- Indexes
CREATE INDEX idx_ai_classifications_transaction_id ON ai_classifications (transaction_id);
CREATE INDEX idx_ai_classifications_suggested_category ON ai_classifications (suggested_category_id);
CREATE INDEX idx_ai_classifications_confirmed_category ON ai_classifications (confirmed_category_id);
CREATE INDEX idx_ai_classifications_confidence ON ai_classifications (confidence_score);
CREATE INDEX idx_ai_classifications_model_version ON ai_classifications (model_version);
CREATE INDEX idx_ai_classifications_was_corrected ON ai_classifications (was_corrected);

-- Full-text search index for original_text
CREATE INDEX idx_ai_classifications_original_text_trgm ON ai_classifications 
    USING gin (original_text gin_trgm_ops);

-- Comments
COMMENT ON TABLE ai_classifications IS 'Stores AI-based transaction classification data for learning';
COMMENT ON COLUMN ai_classifications.confidence_score IS 'AI confidence score between 0 and 1';
COMMENT ON COLUMN ai_classifications.original_text IS 'Original transaction description used for classification';
COMMENT ON COLUMN ai_classifications.was_corrected IS 'TRUE if user changed the suggested category';
COMMENT ON COLUMN ai_classifications.feature_vector IS 'Features extracted for ML model training';
