-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Main table for storing document chunks with embeddings
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    chunk_text TEXT NOT NULL,
    source_file VARCHAR(255) NOT NULL,
    section_title VARCHAR(255),
    chunk_index INTEGER NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast vector similarity search using IVFFlat
CREATE INDEX idx_embedding ON document_chunks 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Index for filtering by source file
CREATE INDEX idx_source_file ON document_chunks(source_file);

-- Index for filtering by section
CREATE INDEX idx_section_title ON document_chunks(section_title);

-- Index for metadata queries
CREATE INDEX idx_metadata ON document_chunks USING gin(metadata);

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update timestamps
CREATE TRIGGER update_document_chunks_updated_at 
BEFORE UPDATE ON document_chunks 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- Table for storing chat history and analytics
CREATE TABLE chat_logs (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(255),
    department VARCHAR(255),
    question TEXT NOT NULL,
    answer TEXT,
    sources JSONB,
    tokens_used INTEGER,
    response_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for user analytics
CREATE INDEX idx_chat_user ON chat_logs(user_name);
CREATE INDEX idx_chat_department ON chat_logs(department);
CREATE INDEX idx_chat_created ON chat_logs(created_at);

-- View for analytics dashboard
CREATE VIEW chat_analytics AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as total_queries,
    COUNT(CASE WHEN success = true THEN 1 END) as successful_queries,
    AVG(response_time_ms) as avg_response_time,
    SUM(tokens_used) as total_tokens,
    COUNT(DISTINCT user_name) as unique_users
FROM chat_logs
GROUP BY DATE_TRUNC('day', created_at);

-- Sample data insertion (for testing)
/*
INSERT INTO document_chunks (chunk_text, source_file, section_title, chunk_index, metadata, embedding)
VALUES 
(
    'All full-time employees are entitled to 15 days of paid vacation per year. Vacation days accrue at a rate of 1.25 days per month.',
    'employee_handbook_2024.pdf',
    'Time Off Policies',
    1,
    '{"chapter": "Benefits", "page": 23}',
    -- Embedding would be inserted here as array[1536 dimensions]
    NULL
),
(
    'Employees must submit vacation requests at least two weeks in advance through the HR portal. Manager approval is required for all time off.',
    'employee_handbook_2024.pdf',
    'Time Off Policies',
    2,
    '{"chapter": "Benefits", "page": 24}',
    NULL
),
(
    'Health insurance coverage begins on the first day of employment. The company covers 80% of premiums for employee coverage.',
    'employee_handbook_2024.pdf',
    'Health Benefits',
    1,
    '{"chapter": "Benefits", "page": 30}',
    NULL
);
*/

-- Performance optimization settings
-- These should be adjusted based on your specific hardware and usage patterns
/*
ALTER TABLE document_chunks SET (fillfactor = 90);
SET max_parallel_workers_per_gather = 4;
SET work_mem = '256MB';
SET maintenance_work_mem = '1GB';
*/

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT ON document_chunks TO n8n_user;
-- GRANT INSERT ON chat_logs TO n8n_user;