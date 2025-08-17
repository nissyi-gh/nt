require_relative '../database'

module NT
  class TaskManager
    module DatabaseRepository
      attr_reader :tasks, :db

      def initialize_repository(use_database: true, db_path: nil)
        @use_database = use_database

        if @use_database
          @db = Database.new(db_path: db_path)
          load_tasks_from_database
        else
          @tasks = []
          @next_id = 1
        end
      end

      def load_tasks_from_database
        @tasks = @db.all_tasks
        @next_id = @db.next_id
      end

      def store_task(task)
        if @use_database
          if task.id == @next_id
            saved_id = @db.insert_task(task)
            task.instance_variable_set(:@id, saved_id)
          else
            @db.save_task(task)
          end
        end

        @tasks << task unless @tasks.include?(task)
        task
      end

      def generate_next_id
        if @use_database
          @next_id = @db.next_id
        else
          id = @next_id
          @next_id += 1
          id
        end
      end

      def find_task(id)
        return nil if id.nil?

        task = @tasks.find { |t| t.id == id }

        if task.nil? && @use_database
          task = @db.find_task(id)
          @tasks << task if task
        end

        task
      end

      def remove_task(task)
        @db.delete_task(task.id) if @use_database
        @tasks.delete(task)
      end

      def remove_tasks(tasks)
        tasks.each { |task| remove_task(task) }
      end

      def all_tasks
        @tasks
      end

      def task_exists?(id)
        if @use_database
          @db.task_exists?(id)
        else
          !find_task(id).nil?
        end
      end

      def persist_task(task)
        @db.update_task(task) if @use_database
      end

      def close_database
        @db&.close
      end

      def reload
        load_tasks_from_database if @use_database
      end
    end
  end
end
