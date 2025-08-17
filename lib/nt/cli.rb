require 'io/console'
require 'io/wait'
require_relative 'cli/date_parser'
require_relative 'cli/display_module'
require_relative 'cli/navigation_module'
require_relative 'cli/command_module'
require_relative 'cli/markdown_formatter'

module NT
  class CLI
    include CLI::DateParser
    include CLI::DisplayModule
    include CLI::NavigationModule
    include CLI::CommandModule
    include CLI::MarkdownFormatter

    def initialize(task_manager: nil)
      @task_manager = task_manager || TaskManager.new
      @running = true
      @selected_index = 0
      @mode = :navigation  # :navigation or :command
      @all_tasks = []
      @id_buffer = ""
      @id_input_time = nil
    end

    def run
      while @running
        clear_screen
        display_tasks

        if @mode == :navigation
          show_navigation_prompt
          handle_navigation_input
        else
          show_prompt
          handle_input
        end
      end

      puts "\nBye!"
    end
  end
end
