module NT
  class TaskManager
    module Statistics
      def statistics
        {
          total: all_tasks.count,
          completed: completed_tasks.count,
          incomplete: incomplete_tasks.count,
          overdue: overdue_tasks.count,
          due_today: tasks_due_today.count,
          due_soon: tasks_due_soon.count,
          with_due_date: tasks_with_due_date.count,
          root_tasks: root_tasks.count,
          child_tasks: child_tasks.count
        }
      end

      def completion_rate
        total = all_tasks.count
        return 0 if total == 0
        (completed_tasks.count.to_f / total * 100).round(1)
      end

      def on_time_rate
        with_due = tasks_with_due_date
        return 0 if with_due.empty?

        on_time = with_due.count { |task| !task.overdue? || task.completed? }
        (on_time.to_f / with_due.count * 100).round(1)
      end

      def depth_statistics
        return { max: 0, average: 0 } if all_tasks.empty?

        depths = all_tasks.map(&:depth)
        {
          max: depths.max,
          average: (depths.sum.to_f / depths.count).round(1)
        }
      end

      def children_count_by_parent
        parent_tasks.map { |parent|
          [parent.id, parent.children.count]
        }.to_h
      end

      def summary
        stats = statistics
        {
          overview: "#{stats[:completed]}/#{stats[:total]} tasks completed",
          completion_rate: "#{completion_rate}%",
          urgent: {
            overdue: stats[:overdue],
            due_today: stats[:due_today],
            due_soon: stats[:due_soon]
          },
          structure: {
            root_tasks: stats[:root_tasks],
            child_tasks: stats[:child_tasks],
            max_depth: depth_statistics[:max]
          }
        }
      end
    end
  end
end
