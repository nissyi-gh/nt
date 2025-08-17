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

      def colorize(text, color)
        return text unless STDIN.tty? && color_supported?

        color_code = COLORS[color] || COLORS[:reset]
        "#{color_code}#{text}#{COLORS[:reset]}"
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
