module NT
  class TaskManager
    module Operations
      def add(title, parent_id: nil, due_date: nil)
        validate_title(title)

        parent = find_task(parent_id) if parent_id
        raise ArgumentError, "Parent task not found: #{parent_id}" if parent_id && !parent

        task = Task.new(
          id: generate_next_id,
          title: title,
          parent: parent,
          due_date: due_date
        )

        store_task(task)
        task
      end

      def delete(id)
        task = find_task(id)
        return false unless task

        remove_tasks(task.descendants)

        task.parent&.remove_child(task)

        remove_task(task)
        true
      end

      def complete(id)
        task = find_task(id)
        return false unless task

        task.complete!
        true
      end

      def uncomplete(id)
        task = find_task(id)
        return false unless task

        task.instance_variable_set(:@completed, false)
        true
      end

      def edit_title(id, new_title)
        task = find_task(id)
        return false unless task

        validate_title(new_title)
        task.update_title(new_title)
        true
      end

      def edit_due_date(id, new_due_date)
        task = find_task(id)
        return false unless task

        task.update_due_date(new_due_date)
        true
      end

      def move_task(task_id, new_parent_id)
        task = find_task(task_id)
        return false unless task

        if new_parent_id
          new_parent = find_task(new_parent_id)
          return false unless new_parent

          return false if new_parent.ancestors.include?(task)
        end

        task.parent&.remove_child(task)

        if new_parent_id
          new_parent = find_task(new_parent_id)
          new_parent.add_child(task)
        else
          task.instance_variable_set(:@parent, nil)
        end

        true
      end

      def complete_all(task_ids)
        task_ids.map { |id| complete(id) }.all?
      end

      def delete_all(task_ids)
        task_ids.map { |id| delete(id) }.all?
      end

      private

      def validate_title(title)
        raise ArgumentError, "Title cannot be empty" if title.nil? || title.strip.empty?
      end
    end
  end
end
