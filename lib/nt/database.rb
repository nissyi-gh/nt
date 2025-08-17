require 'sqlite3'
require 'date'
require 'fileutils'

module NT
  class Database
    DEFAULT_DB_PATH = File.expand_path('~/.nt/tasks.db')

    attr_reader :db

    def initialize(db_path: nil)
      @db_path = db_path || DEFAULT_DB_PATH
      ensure_database_directory
      @db = SQLite3::Database.new(@db_path)
      @db.results_as_hash = true
      @db.execute("PRAGMA foreign_keys = ON")

      initialize_schema
    end

    def close
      @db.close if @db && !@db.closed?
    end

    def save_task(task)
      if task_exists?(task.id)
        update_task(task)
      else
        insert_task(task)
      end
    end

    def insert_task(task)
      sql = <<-SQL
        INSERT INTO tasks (title, completed, parent_id, due_date)
        VALUES (?, ?, ?, ?)
      SQL

      @db.execute(sql, [
        task.title,
        task.completed? ? 1 : 0,
        task.parent&.id,
        task.due_date&.to_s
      ])

      @db.last_insert_row_id
    end

    def update_task(task)
      sql = <<-SQL
        UPDATE tasks
        SET title = ?, completed = ?, parent_id = ?, due_date = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      SQL

      @db.execute(sql, [
        task.title,
        task.completed? ? 1 : 0,
        task.parent&.id,
        task.due_date&.to_s,
        task.id
      ])
    end

    def delete_task(id)
      @db.execute("DELETE FROM tasks WHERE id = ?", [id])
    end

    def find_task(id)
      result = @db.get_first_row("SELECT * FROM tasks WHERE id = ?", [id])
      result ? build_task_from_row(result) : nil
    end

    def all_tasks
      results = @db.execute("SELECT * FROM tasks ORDER BY id")
      build_tasks_with_hierarchy(results)
    end

    def root_tasks
      results = @db.execute("SELECT * FROM tasks WHERE parent_id IS NULL ORDER BY id")
      build_tasks_with_hierarchy(results)
    end

    def children_of(parent_id)
      results = @db.execute("SELECT * FROM tasks WHERE parent_id = ? ORDER BY id", [parent_id])
      build_tasks_with_hierarchy(results)
    end

    def task_exists?(id)
      result = @db.get_first_value("SELECT COUNT(*) FROM tasks WHERE id = ?", [id])
      result > 0
    end

    def next_id
      @db.get_first_value("SELECT COALESCE(MAX(id), 0) + 1 FROM tasks")
    end

    def clear_all
      @db.execute("DELETE FROM tasks")
    end

    private

    def ensure_database_directory
      dir = File.dirname(@db_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
    end

    def initialize_schema
      schema_sql = File.read(File.join(File.dirname(__FILE__), '../../db/schema.sql'))
      @db.execute_batch(schema_sql)
    end

    def build_task_from_row(row)
      id = row['id'] || row[:id]
      title = row['title'] || row[:title]
      completed = row['completed'] || row[:completed]
      due_date_str = row['due_date'] || row[:due_date]

      Task.new(
        id: id.to_i,
        title: title.to_s,
        parent: nil,
        due_date: due_date_str ? Date.parse(due_date_str.to_s) : nil
      ).tap do |task|
        task.complete! if completed.to_i == 1
      end
    end

    def build_tasks_with_hierarchy(rows)
      tasks = {}
      parent_child_map = {}

      rows.each do |row|
        task = build_task_from_row(row)
        task_id = (row['id'] || row[:id]).to_i
        parent_id = row['parent_id'] || row[:parent_id]

        tasks[task_id] = task
        parent_child_map[task_id] = parent_id.to_i if parent_id
      end

      parent_child_map.each do |child_id, parent_id|
        next unless parent_id

        child_task = tasks[child_id]
        parent_task = tasks[parent_id]

        if parent_task
          parent_task.add_child(child_task)
        end
      end

      tasks.values
    end
  end
end
