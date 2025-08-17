require_relative 'task/hierarchical'
require_relative 'task/due_date'
require_relative 'task/formatter'

module NT
  class Task
    include Hierarchical
    include DueDate
    include Formatter

    attr_reader :id, :title, :completed, :parent, :children, :due_date

    def initialize(id:, title:, parent: nil, due_date: nil)
      @id = id
      @title = title
      @completed = false
      @parent = parent
      @children = []
      @due_date = parse_due_date(due_date)

      parent&.add_child(self)
    end

    def complete!
      @completed = true
    end

    def update_title(new_title)
      raise ArgumentError, "Title cannot be empty" if new_title.nil? || new_title.strip.empty?
      @title = new_title
    end

    def completed?
      @completed
    end
  end
end
