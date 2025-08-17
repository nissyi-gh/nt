require 'date'
require 'io/console'

module NT
  class CLI
    def initialize(task_manager: nil)
      @task_manager = task_manager || TaskManager.new
      @running = true
    end

    def run
      while @running
        clear_screen
        display_tasks
        show_prompt
        handle_input
      end

      puts "\nBye!"
    end

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

      # Task list
      root_tasks = @task_manager.root_tasks
      
      # Calculate available space for tasks (leave room for header, stats, and prompt)
      # Header: 4 lines, Stats: 3 lines, Prompt: 5 lines, Buffer: 2 lines
      reserved_lines = 14
      available_lines = [height - reserved_lines, 5].max
      
      if root_tasks.empty?
        puts "No tasks yet. Use 'add <title>' to create a task."
      else
        # Collect all task lines
        task_lines = []
        root_tasks.each do |task|
          task_lines.concat(task.to_s.split("\n"))
        end
        
        # Display tasks within available space
        if task_lines.length <= available_lines
          task_lines.each { |line| puts line }
        else
          # Show truncated list with scroll indicator
          displayed_lines = available_lines - 1
          task_lines.first(displayed_lines).each { |line| puts line }
          puts "... (#{task_lines.length - displayed_lines} more lines, scroll to see all)"
        end
      end
      
      # Fill remaining space to push stats to bottom
      current_line_count = 4  # Header lines
      current_line_count += root_tasks.empty? ? 1 : [task_lines.length, available_lines].min
      
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

    def show_prompt
      width = terminal_size[1]
      puts "-" * [width, 50].min
      puts "Commands: add <title> | add-child <parent_id> <title> | complete <id>"
      puts "          edit <id> <title> | due <id> <date> | delete <id> | exit"
      puts "          (date: YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', 'none')"
      print "> "
    end

    # @TODO
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

    def parse_date_string(date_str)
      case date_str.downcase
      when 'none', 'clear'
        nil
      when 'today'
        Date.today
      when 'tomorrow'
        Date.today + 1
      else
        # Try different date formats
        parsed_date = nil
        
        # YYYYMMDD format (e.g., 20251231)
        if date_str.match?(/^\d{8}$/)
          year = date_str[0..3].to_i
          month = date_str[4..5].to_i
          day = date_str[6..7].to_i
          begin
            parsed_date = Date.new(year, month, day)
          rescue Date::Error
            # Invalid date
          end
        # MMDD format (e.g., 1231 for December 31st of current year)
        elsif date_str.match?(/^\d{4}$/)
          month = date_str[0..1].to_i
          day = date_str[2..3].to_i
          year = Date.today.year
          begin
            parsed_date = Date.new(year, month, day)
            # If the date has already passed this year, assume next year
            if parsed_date < Date.today
              parsed_date = Date.new(year + 1, month, day)
            end
          rescue Date::Error
            # Invalid date
          end
        else
          # Try standard parse for YYYY-MM-DD and other formats
          begin
            parsed_date = Date.parse(date_str)
          rescue Date::Error
            # Invalid date
          end
        end
        
        if parsed_date.nil?
          raise ArgumentError, "Invalid date format. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'"
        end
        
        parsed_date
      end
    end
  end
end
