module NT
  class Task
    module Formatter
      def to_s(indent_level: 0)
        status = @completed ? "[✓]" : "[ ]"
        indent = "  " * indent_level

        due_info = format_due_date_info
        result = "#{indent}#{status} #{@id}: #{@title}#{due_info}"

        if @children.any?
          child_strings = @children.map { |child| child.to_s(indent_level: indent_level + 1) }
          result + "\n" + child_strings.join("\n")
        else
          result
        end
      end

      private

      def format_due_date_info
        return "" if @due_date.nil?

        if @completed
          " (期限: #{@due_date})"
        elsif respond_to?(:overdue?) && overdue?
          " ⚠️ (期限切れ: #{@due_date})"
        elsif respond_to?(:due_today?) && due_today?
          " 📅 (本日期限)"
        elsif respond_to?(:due_soon?) && due_soon?
          " ⏰ (期限: #{@due_date})"
        else
          " (期限: #{@due_date})"
        end
      end
    end
  end
end
