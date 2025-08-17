require_relative 'task_manager/database_repository'
require_relative 'task_manager/query'
require_relative 'task_manager/statistics'
require_relative 'task_manager/operations'

module NT
  class TaskManager
    include DatabaseRepository
    include Query
    include Statistics
    include Operations

    def initialize(use_database: true, db_path: nil)
      initialize_repository(use_database: use_database, db_path: db_path)
    end

    def complete(id)
      task = find_task(id)
      return false unless task

      task.complete!
      persist_task(task) if respond_to?(:persist_task)
      true
    end

    def edit_title(id, new_title)
      task = find_task(id)
      return false unless task

      validate_title(new_title)
      task.update_title(new_title)
      persist_task(task) if respond_to?(:persist_task)
      true
    end

    def edit_due_date(id, new_due_date)
      task = find_task(id)
      return false unless task

      task.update_due_date(new_due_date)
      persist_task(task) if respond_to?(:persist_task)
      true
    end

    def edit_reference_url(id, new_url)
      task = find_task(id)
      return false unless task

      task.update_reference_url(new_url)
      persist_task(task) if respond_to?(:persist_task)
      true
    end

    def close
      close_database if respond_to?(:close_database)
    end
  end
end
