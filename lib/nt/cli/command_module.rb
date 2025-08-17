module NT
  class CLI
    module CommandModule
      private

      def handle_input
        input = gets&.chomp
        return unless input

        parts = input.split(" ", 3)
        command = parts[0]&.downcase

        case command
        when "add", "a"
          add_task(parts[1..-1].join(" "))
        when "add-child", "ac"
          add_child_task(parts[1]&.to_i, parts[2..-1]&.join(" "))
        when "complete", "c"
          complete_task(parts[1]&.to_i)
        when "edit", "e"
          edit_task(parts[1]&.to_i, parts[2..-1]&.join(" "))
        when "due"
          edit_due_date(parts[1]&.to_i, parts[2])
        when "delete", "d"
          delete_task(parts[1]&.to_i)
        when "exit", "q"
          @running = false
        when nil, ""
          # Just redraw
        else
          puts "Unknown command: #{command}"
          sleep(0.5)
        end
      rescue Interrupt
        puts "\n\nInterrupt!"
        @running = false
      end

      def add_task(title)
        return if title.nil? || title.strip.empty?

        begin
          task = @task_manager.add(title)
          puts "Added: #{task.to_s}"
          sleep(1)
        rescue ArgumentError => e
          puts "Error: #{e.message}"
          sleep(1)
        end
      end

      def add_child_task(parent_id, title)
        if parent_id.nil?
          puts "Error: Parent ID is required. Usage: add-child <parent_id> <title>"
          sleep(1)
          return
        end

        if title.nil? || title.strip.empty?
          puts "Error: Title is required. Usage: add-child <parent_id> <title>"
          sleep(1)
          return
        end

        begin
          task = @task_manager.add(title, parent_id: parent_id)
          puts "Added child task: #{task.to_s}"
          sleep(1)
        rescue ArgumentError => e
          puts "Error: #{e.message}"
          sleep(1)
        end
      end

      def complete_task(id)
        return unless id

        if @task_manager.complete(id)
          puts "Task #{id} completed!"
        else
          puts "Task #{id} not found."
        end
        sleep(1)
      end

      def edit_task(id, new_title)
        return unless id && new_title && !new_title.strip.empty?

        if @task_manager.edit_title(id, new_title)
          puts "Task #{id} updated!"
        else
          puts "Task #{id} not found."
        end
        sleep(1)
      end

      def delete_task(id)
        return unless id

        if @task_manager.delete(id)
          puts "Task #{id} deleted!"
        else
          puts "Task #{id} not found."
        end
        sleep(1)
      end

      def edit_due_date(id, date_str)
        return unless id

        if date_str.nil? || date_str.strip.empty?
          puts "Error: Date is required. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'"
          sleep(1)
          return
        end

        begin
          due_date = parse_date_string(date_str)

          if @task_manager.edit_due_date(id, due_date)
            if due_date.nil?
              puts "Due date cleared for task #{id}"
            else
              puts "Due date set to #{due_date} for task #{id}"
            end
          else
            puts "Task #{id} not found."
          end
          sleep(1)
        rescue ArgumentError => e
          puts "Error: #{e.message}"
          sleep(1)
        end
      end
    end
  end
end
