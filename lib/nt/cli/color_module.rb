module NT
  class CLI
    module ColorModule
      # ANSI color codes
      COLORS = {
        green: "\e[32m",
        red: "\e[31m",
        yellow: "\e[33m",
        blue: "\e[34m",
        magenta: "\e[35m",
        cyan: "\e[36m",
        reset: "\e[0m"
      }.freeze

      # ANSI style codes
      STYLES = {
        underline: "\e[4m",
        bold: "\e[1m",
        reset: "\e[0m"
      }.freeze

      def colorize(text, color, style = nil)
        return text unless STDIN.tty? && color_supported?

        result = text

        # Apply style if specified
        if style && STYLES[style]
          result = "#{STYLES[style]}#{result}"
        end

        # Apply color
        if color && COLORS[color]
          result = "#{COLORS[color]}#{result}"
        end

        # Reset at the end
        "#{result}#{COLORS[:reset]}"
      end

      def underline(text)
        return text unless STDIN.tty? && color_supported?
        "#{STYLES[:underline]}#{text}#{STYLES[:reset]}"
      end

      private

      def color_supported?
        # Check if terminal supports colors
        return false if ENV['NO_COLOR']
        return true if ENV['FORCE_COLOR']

        # Check common environment variables
        term = ENV['TERM']
        return false if term.nil? || term == 'dumb'

        # Most modern terminals support colors
        true
      end
    end
  end
end
