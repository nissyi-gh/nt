require 'date'

module NT
  class Task
    module DueDate
      def update_due_date(new_due_date)
        @due_date = parse_due_date(new_due_date)
      end

      def overdue?
        return false if @due_date.nil? || @completed
        @due_date < Date.today
      end

      def due_today?
        return false if @due_date.nil?
        @due_date == Date.today
      end

      def due_soon?(days = 3)
        return false if @due_date.nil? || @completed
        @due_date <= Date.today + days && @due_date >= Date.today
      end

      def days_until_due
        return nil if @due_date.nil?
        (@due_date - Date.today).to_i
      end

      private

      def parse_due_date(date_input)
        return nil if date_input.nil?

        case date_input
        when Date
          date_input
        when String
          Date.parse(date_input)
        when Time, DateTime
          date_input.to_date
        else
          raise ArgumentError, "Invalid date format"
        end
      rescue Date::Error => e
        raise ArgumentError, "Invalid date string: #{e.message}"
      end
    end
  end
end
