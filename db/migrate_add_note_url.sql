-- Migration to add reference_url column to tasks table

-- Add reference_url column if it doesn't exist
ALTER TABLE tasks ADD COLUMN reference_url TEXT;
