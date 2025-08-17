-- NT Task Manager Database Schema

-- タスクテーブル
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    completed BOOLEAN DEFAULT 0,
    parent_id INTEGER,
    due_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- 親子関係の確認を高速化するためのインデックス
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON tasks(parent_id);

-- 期限での検索を高速化するためのインデックス
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);

-- 完了状態での検索を高速化するためのインデックス
CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed);
