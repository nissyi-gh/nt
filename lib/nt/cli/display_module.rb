module NT
  class CLI
    module DisplayModule
      private

      def clear_screen
        system("clear")
      end

      def terminal_size
        IO.console&.winsize || [24, 80]  # Default to 24 rows, 80 columns
      end

      def display_tasks
        height, width = terminal_size

        # Header
        puts "=" * [width, 50].min
        puts " NT Task Manager".center([width, 50].min)
        puts "=" * [width, 50].min
        puts

        # Get all tasks in flat list for selection
        @all_tasks = collect_all_tasks(@task_manager.root_tasks)

        # Calculate available space for tasks (leave room for header, stats, and prompt)
        # Header: 4 lines, Stats: 3 lines, Prompt: 5 lines, Buffer: 2 lines
        reserved_lines = 14
        available_lines = [height - reserved_lines, 5].max

        if @all_tasks.empty?
          puts "No tasks yet. Use 'add <title>' to create a task."
        else
          # Display tasks with selection indicator
          display_tasks_with_selection(available_lines)
        end

        # Fill remaining space to push stats to bottom
        current_line_count = 4  # Header lines
        current_line_count += @all_tasks.empty? ? 1 : [@all_tasks.length, available_lines].min

        lines_to_fill = height - current_line_count - 8  # 8 for stats and prompt
        lines_to_fill.times { puts } if lines_to_fill > 0

        # Statistics at bottom
        stats = @task_manager.statistics
        if stats[:total] > 0
          puts "-" * [width, 50].min
          puts "Total: #{stats[:total]} | Completed: #{stats[:completed]} | " \
               "Overdue: #{stats[:overdue]} | Due Today: #{stats[:due_today]}"
        end
      end

      def collect_all_tasks(tasks, depth = 0, result = [])
        tasks.each do |task|
          result << { task: task, depth: depth }
          collect_all_tasks(task.children, depth + 1, result) if task.children.any?
        end
        result
      end

      def display_tasks_with_selection(available_lines)
        # Ensure selected_index is within bounds
        @selected_index = [[@selected_index, 0].max, @all_tasks.length - 1].min if @all_tasks.any?

        # Calculate scroll window
        start_index = 0
        end_index = [@all_tasks.length - 1, 0].max

        if @all_tasks.length > available_lines
          # Implement scrolling
          if @selected_index < available_lines / 2
            start_index = 0
            end_index = [available_lines - 1, @all_tasks.length - 1].min
          elsif @selected_index > @all_tasks.length - available_lines / 2
            start_index = [@all_tasks.length - available_lines, 0].max
            end_index = @all_tasks.length - 1
          else
            start_index = [@selected_index - available_lines / 2, 0].max
            end_index = [start_index + available_lines - 1, @all_tasks.length - 1].min
          end
        end

        # Display tasks
        (start_index..end_index).each do |i|
          break if i >= @all_tasks.length || i < 0
          task_info = @all_tasks[i]
          next unless task_info

          task = task_info[:task]
          depth = task_info[:depth]

          # Selection indicator
          indicator = (i == @selected_index && @mode == :navigation) ? "→ " : "  "

          # Indentation
          indent = "  " * depth

          # Task display
          checkbox = task.completed? ? "[✓]" : "[ ]"
          task_line = "#{indicator}#{indent}#{checkbox} #{task.id}: #{task.title}"
          
          # Add URL indicator
          if task.reference_url && !task.reference_url.empty?
            task_line += " 🔗"
          end

          # Add due date info if present
          if task.due_date
            if task.overdue?
              task_line += " ⚠️ (期限切れ: #{task.due_date})"
            elsif task.due_today?
              task_line += " 📅 (本日期限)"
            elsif task.due_soon?
              task_line += " ⏰ (期限: #{task.due_date})"
            else
              task_line += " (期限: #{task.due_date})"
            end
          end

          # Apply color based on priority
          # Selected task takes precedence (green)
          if i == @selected_index && @mode == :navigation
            task_line = colorize(task_line, :green)
          # Otherwise, color based on due date status
          elsif !task.completed? && task.due_date
            if task.overdue?
              task_line = colorize(task_line, :red)
            elsif task.due_soon?
              task_line = colorize(task_line, :yellow)
            end
          end
          
          puts task_line
        end

        # Show scroll indicator if needed
        if @all_tasks.length > available_lines
          if end_index < @all_tasks.length - 1
            puts "  ... (#{@all_tasks.length - end_index - 1} more tasks below)"
          end
        end
      end

      def show_prompt
        width = terminal_size[1]
        puts "-" * [width, 50].min
        puts "Commands: add <title> | add-child <parent_id> <title> | complete <id>"
        puts "          edit <id> <title> | due <id> <date> | delete <id> | exit"
        puts "          (date: YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', 'none')"
        print "> "
      end

      def show_navigation_prompt
        width = terminal_size[1]
        puts "-" * [width, 50].min

        if @all_tasks.empty?
          puts "Press 'a' to add a task, 'q' to quit"
        else
          selected_task = @all_tasks[@selected_index][:task] if @all_tasks[@selected_index]
          if selected_task
            status_line = "Selected: #{selected_task.title} (ID: #{selected_task.id})"
            status_line += " | Typing ID: #{@id_buffer}" if @id_buffer.length > 0
            puts status_line
          end
          puts "↑/↓: Navigate | Enter: Actions | i: Details | a: Add | m: Export | /: Cmd | q: Quit"
        end
      end
    end
  end
end
