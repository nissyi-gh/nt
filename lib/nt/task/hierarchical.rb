module NT
  class Task
    module Hierarchical
      def add_child(task)
        return if @children.include?(task)
        @children << task
        task.instance_variable_set(:@parent, self) unless task.parent == self
      end

      def remove_child(task)
        @children.delete(task)
        task.instance_variable_set(:@parent, nil) if task.parent == self
      end

      def root?
        @parent.nil?
      end

      def leaf?
        @children.empty?
      end

      def depth
        return 0 if root?
        parent.depth + 1
      end

      def ancestors
        return [] if root?
        [parent] + parent.ancestors
      end

      def descendants
        children + children.flat_map(&:descendants)
      end

      def siblings
        return [] if root?
        parent.children - [self]
      end
    end
  end
end
