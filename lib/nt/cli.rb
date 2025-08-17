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

    def display_tasks
      puts "=" * 50
      puts " NT Task Manager"
      puts "=" * 50
      puts

      root_tasks = @task_manager.root_tasks

      if root_tasks.empty?
        puts "No tasks yet. Use 'add <title>' to create a task."
      else
        root_tasks.each do |task|
          puts task.to_s
        end
      end

      puts
      stats = @task_manager.statistics
      if stats[:total] > 0
        puts "-" * 50
        puts "Total: #{stats[:total]} | Completed: #{stats[:completed]} | " \
             "Overdue: #{stats[:overdue]} | Due Today: #{stats[:due_today]}"
      end
    end

    def show_prompt
      puts "-" * 50
      puts "Commands: add <title> | add-child <parent_id> <title> | complete <id>"
      puts "          edit <id> <title> | delete <id> | exit"
      print "> "
    end

    # @TODO
    def handle_input
      input = gets&.chomp
      return unless input

      parts = input.split(" ", 3)
      puts parts
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
  end
end
