require_relative "nt/task"
require_relative "nt/database"
require_relative "nt/task_manager"
require_relative "nt/cli"

module NT
  def self.run
    cli = CLI.new
    cli.run
  end
end
