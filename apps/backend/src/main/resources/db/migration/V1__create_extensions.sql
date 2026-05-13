-- ============================================
-- FYNA - Finance AI Application
-- Migration V1: Extensions and Base Setup
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for text search optimization
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
