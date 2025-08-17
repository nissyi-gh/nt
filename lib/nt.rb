require_relative "nt/cli"

module NT
  def self.run
    cli = CLI.new
    cli.run
  end
end
