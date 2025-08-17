module NT
  class CLI
    module NavigationModule
      private

      def handle_navigation_input
        # Check for ID buffer timeout (1 second)
        if @id_input_time && (Time.now - @id_input_time > 1)
          process_id_buffer
        end

        input = get_single_char

        case input
        when "\e"  # Escape sequence (arrow keys)
          clear_id_buffer
          # Read the rest of the escape sequence
          begin
            seq = STDIN.read_nonblock(2)
            case seq
            when "[A"  # Up arrow
              @selected_index -= 1 if @selected_index > 0 && @all_tasks.any?
            when "[B"  # Down arrow
              if @all_tasks.any?
                max_index = @all_tasks.length - 1
                @selected_index += 1 if @selected_index < max_index
              end
            end
          rescue IO::WaitReadable
            # No more input available
          end
        when "\r", "\n"  # Enter
          if @id_buffer.length > 0
            # Process ID buffer if we have digits
            process_id_buffer
          else
            show_task_actions_menu if @all_tasks.any?
          end
        when "a", "A"
          clear_id_buffer
          @mode = :command
          add_task_interactive
          @mode = :navigation
        when "/"
          clear_id_buffer
          @mode = :command
        when "m", "M"
          clear_id_buffer
          export_to_markdown
        when "i", "I"
          clear_id_buffer
          show_task_details if @all_tasks.any?
        when "q", "Q"
          clear_id_buffer
          @running = false
        when "0".."9"
          # Accumulate digits in buffer
          @id_buffer += input
          @id_input_time = Time.now
        when "\x7f", "\b"  # Backspace
          @id_buffer = @id_buffer[0..-2] if @id_buffer.length > 0
          @id_input_time = Time.now if @id_buffer.length > 0
        when "\x03"  # Ctrl-C
          clear_id_buffer
        end
      end

      def process_id_buffer
        return if @id_buffer.empty?

        task_id = @id_buffer.to_i
        index = @all_tasks.find_index { |t| t[:task].id == task_id }
        @selected_index = index if index
        clear_id_buffer
      end

      def clear_id_buffer
        @id_buffer = ""
        @id_input_time = nil
      end

      def get_single_char
        if STDIN.tty?
          STDIN.raw do |io|
            io.getch
          end
        else
          # Fallback for non-TTY (e.g., pipe input)
          STDIN.getc
        end
      end

      def show_task_actions_menu
        return unless @all_tasks[@selected_index]

        task = @all_tasks[@selected_index][:task]

        puts "\n" + "=" * 30
        puts "Task: #{task.title}"
        if task.reference_url && !task.reference_url.empty?
          puts "URL: #{task.reference_url}"
        end
        puts "=" * 30
        puts "[C] Complete/Uncomplete"
        puts "[E] Edit title"
        puts "[D] Set due date"
        puts "[U] Edit URL"
        puts "[V] View/Open URL"
        puts "[A] Add child task"
        puts "[X] Delete task"
        puts "[ESC] Cancel"
        print "Choose action: "

        action = get_single_char

        case action
        when "1", "c", "C"
          if task.completed?
            @task_manager.uncomplete(task.id)
          else
            @task_manager.complete(task.id)
          end
        when "2", "e", "E"
          print "\nNew title: "
          new_title = gets.chomp
          @task_manager.edit_title(task.id, new_title) unless new_title.empty?
        when "3", "d", "D"
          print "\nDue date (YYYY-MM-DD, YYYYMMDD, MMDD, today, tomorrow, none): "
          date_str = gets.chomp
          unless date_str.empty?
            begin
              due_date = parse_date_string(date_str)
              @task_manager.edit_due_date(task.id, due_date)
            rescue ArgumentError => e
              puts "Error: #{e.message}"
              sleep(1)
            end
          end
        when "u", "U"
          puts "\nCurrent URL: #{task.reference_url || '(none)'}"
          print "New URL (leave empty to clear): "
          new_url = gets.chomp
          @task_manager.edit_reference_url(task.id, new_url.empty? ? nil : new_url)
        when "v", "V"
          if task.reference_url && !task.reference_url.empty?
            puts "\nURL: #{task.reference_url}"
            print "Open in browser? (y/N): "
            confirm = get_single_char
            if confirm.downcase == 'y'
              system("open '#{task.reference_url}'") if RUBY_PLATFORM =~ /darwin/
              system("xdg-open '#{task.reference_url}'") if RUBY_PLATFORM =~ /linux/
              system("start '#{task.reference_url}'") if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
            end
          else
            puts "\nNo URL set for this task"
            sleep(1)
          end
        when "4", "a", "A"
          print "\nChild task title: "
          child_title = gets.chomp
          @task_manager.add(child_title, parent_id: task.id) unless child_title.empty?
        when "5", "x", "X"
          print "\nDelete task '#{task.title}'? (y/N): "
          confirm = get_single_char
          @task_manager.delete(task.id) if confirm.downcase == 'y'
          @selected_index = [@selected_index - 1, 0].max if @selected_index >= @all_tasks.length - 1
        when "0", "\e", "\x03"  # 0, ESC, or Ctrl-C
          # Cancel - do nothing
        end
      end

      def add_task_interactive
        print "\nTask title: "
        title = gets.chomp
        return if title.empty?

        @task_manager.add(title)
        puts "Task added successfully!"
        sleep(0.5)
      end
      
      def show_task_details
        return unless @all_tasks[@selected_index]
        
        task = @all_tasks[@selected_index][:task]
        
        puts "\n" + "=" * 50
        puts " Task Details".center(50)
        puts "=" * 50
        puts
        puts "ID:          #{task.id}"
        puts "Title:       #{task.title}"
        puts "Status:      #{task.completed? ? '✓ Completed' : '○ Incomplete'}"
        
        if task.due_date
          status = if task.overdue?
                    "⚠️ OVERDUE"
                  elsif task.due_today?
                    "📅 Due Today"
                  elsif task.due_soon?
                    "⏰ Due Soon"
                  else
                    "Scheduled"
                  end
          puts "Due Date:    #{task.due_date} (#{status})"
        else
          puts "Due Date:    (not set)"
        end
        
        if task.reference_url && !task.reference_url.empty?
          puts "URL:         #{task.reference_url}"
        else
          puts "URL:         (not set)"
        end
        
        if task.parent
          puts "Parent Task: #{task.parent.title}"
        end
        
        if task.children.any?
          puts "Child Tasks: #{task.children.map(&:title).join(', ')}"
        end
        
        puts
        puts "-" * 50
        puts "Press any key to continue..."
        get_single_char
      end
    end
  end
end
