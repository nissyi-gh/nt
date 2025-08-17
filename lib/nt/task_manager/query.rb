module NT
  class TaskManager
    module Query
      def root_tasks
        all_tasks.select(&:root?)
      end

      def completed_tasks
        all_tasks.select(&:completed?)
      end

      def incomplete_tasks
        all_tasks.reject(&:completed?)
      end

      def overdue_tasks
        all_tasks.select(&:overdue?)
      end

      def tasks_due_today
        all_tasks.select(&:due_today?)
      end

      def tasks_due_soon(days = 3)
        all_tasks.select { |task| task.due_soon?(days) }
      end

      def tasks_with_due_date
        all_tasks.select { |task| task.due_date }
      end

      def child_tasks
        all_tasks.reject(&:root?)
      end

      def parent_tasks
        all_tasks.reject(&:leaf?)
      end

      def children_of(parent_id)
        parent = find_task(parent_id)
        return [] unless parent
        parent.children
      end

      def all_tasks_hierarchical
        root_tasks
      end
    end
  end
end
