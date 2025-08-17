module NT
  class CLI
    module MarkdownFormatter
      def export_to_markdown
        clear_screen
        puts "=" * 50
        puts " Markdown Export".center(50)
        puts "=" * 50
        puts

        markdown_content = generate_markdown

        puts markdown_content
        puts
        puts "-" * 50

        print "Save to file? (y/N): "
        response = get_single_char

        if response&.downcase == 'y'
          save_markdown_to_file(markdown_content)
        else
          puts "\nMarkdown content displayed above. Press any key to continue..."
          get_single_char
        end
      end

      private

      def generate_markdown
        content = []
        content << "# Task List"
        content << ""
        content << "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        content << ""

        # Statistics
        stats = @task_manager.statistics
        content << "## Statistics"
        content << ""
        content << "- Total tasks: #{stats[:total]}"
        content << "- Completed: #{stats[:completed]}"
        content << "- Remaining: #{stats[:total] - stats[:completed]}"
        content << "- Overdue: #{stats[:overdue]}"
        content << "- Due today: #{stats[:due_today]}"
        content << ""

        # Task list
        content << "## Tasks"
        content << ""

        if @task_manager.root_tasks.empty?
          content << "_No tasks yet._"
        else
          append_tasks_as_markdown(@task_manager.root_tasks, content, 0)
        end

        content.join("\n")
      end

      def append_tasks_as_markdown(tasks, content, depth)
        tasks.each do |task|
          indent = "  " * depth
          checkbox = task.completed? ? "[x]" : "[ ]"

          task_line = "#{indent}- #{checkbox} #{task.title}"

          # Add due date metadata if present
          if task.due_date
            if task.overdue?
              task_line += " _(**OVERDUE: #{task.due_date}**)_"
            elsif task.due_today?
              task_line += " _(**DUE TODAY**)_"
            elsif task.due_soon?
              task_line += " _(Due: #{task.due_date})_"
            else
              task_line += " _(Due: #{task.due_date})_"
            end
          end

          content << task_line

          # Recursively add children
          if task.children.any?
            append_tasks_as_markdown(task.children, content, depth + 1)
          end
        end
      end

      def save_markdown_to_file(content)
        print "\nFilename (default: tasks.md): "
        filename = gets.chomp
        filename = "tasks.md" if filename.empty?

        # Ensure .md extension
        filename += ".md" unless filename.end_with?(".md")

        begin
          File.write(filename, content)
          puts "\nSaved to #{filename}"
          puts "Press any key to continue..."
          get_single_char
        rescue => e
          puts "\nError saving file: #{e.message}"
          puts "Press any key to continue..."
          get_single_char
        end
      end
    end
  end
end
