require 'date'

module NT
  class CLI
    module DateParser
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
end
