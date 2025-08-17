module NT
  class CLI
    def initialize
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
      # @TODO
    end

    def show_prompt
      puts "-" * 50
      puts "Commands: add <title> | complete <id> | edit <id> <title> | delete <id> | exit"
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
      when "add"
        # @TODO
      when "complete"
        # @TODO
      when "edit"
        # @TODO
      when "delete"
        # @TODO
      when "exit"
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
  end
end
