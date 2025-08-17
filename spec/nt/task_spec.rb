RSpec.describe NT::Task do
  let(:task) { described_class.new(id: 1, title: "Test task") }
  let(:parent_task) { described_class.new(id: 0, title: "Parent task") }
  let(:child_task) { described_class.new(id: 2, title: "Child task", parent: parent_task) }

  describe '#initialize' do
    it 'sets the id and title' do
      expect(task.id).to eq(1)
      expect(task.title).to eq("Test task")
    end

    it 'sets completed to false by default' do
      expect(task.completed).to be false
    end

    it 'initializes empty children array' do
      expect(task.children).to eq([])
    end

    it 'sets parent to nil by default' do
      expect(task.parent).to be_nil
    end

    context 'with parent specified' do
      it 'sets the parent' do
        expect(child_task.parent).to eq(parent_task)
      end

      it 'adds itself to parent children' do
        expect(parent_task.children).to include(child_task)
      end
    end
  end

  describe '#complete!' do
    it 'marks the task as completed' do
      expect { task.complete! }.to change { task.completed }.from(false).to(true)
    end

    it 'returns true' do
      expect(task.complete!).to be true
    end
  end

  describe '#completed?' do
    context 'when task is not completed' do
      it 'returns false' do
        expect(task.completed?).to be false
      end
    end

    context 'when task is completed' do
      before { task.complete! }

      it 'returns true' do
        expect(task.completed?).to be true
      end
    end
  end

  describe '#update_title' do
    context 'with valid title' do
      it 'updates the title' do
        expect { task.update_title("New title") }.to change { task.title }.from("Test task").to("New title")
      end

      it 'returns the new title' do
        expect(task.update_title("New title")).to eq("New title")
      end
    end

    context 'with empty title' do
      it 'raises ArgumentError for empty string' do
        expect { task.update_title("") }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises ArgumentError for whitespace only' do
        expect { task.update_title("   ") }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises ArgumentError for nil' do
        expect { task.update_title(nil) }.to raise_error(ArgumentError, "Title cannot be empty")
      end
    end
  end

  describe '#to_s' do
    context 'when task is not completed' do
      it 'returns formatted string with empty checkbox' do
        expect(task.to_s).to eq("[ ] 1: Test task")
      end
    end

    context 'when task is completed' do
      before { task.complete! }

      it 'returns formatted string with checked checkbox' do
        expect(task.to_s).to eq("[✓] 1: Test task")
      end
    end

    context 'with children' do
      it 'returns hierarchical string representation' do
        parent = described_class.new(id: 0, title: "Parent task")
        child = described_class.new(id: 2, title: "Child task", parent: parent)
        described_class.new(id: 3, title: "Grandchild", parent: child)

        expected = "[ ] 0: Parent task\n  [ ] 2: Child task\n    [ ] 3: Grandchild"
        expect(parent.to_s).to eq(expected)
      end
    end
  end

  describe '#add_child' do
    it 'adds a child task' do
      task.add_child(child_task)
      expect(task.children).to include(child_task)
    end

    it 'sets the parent of the child' do
      task.add_child(child_task)
      expect(child_task.parent).to eq(task)
    end

    it 'does not add duplicate children' do
      task.add_child(child_task)
      task.add_child(child_task)
      expect(task.children.count(child_task)).to eq(1)
    end
  end

  describe '#remove_child' do
    before { task.add_child(child_task) }

    it 'removes the child' do
      task.remove_child(child_task)
      expect(task.children).not_to include(child_task)
    end

    it 'clears the parent of the child' do
      task.remove_child(child_task)
      expect(child_task.parent).to be_nil
    end
  end

  describe '#root?' do
    it 'returns true for root task' do
      expect(task.root?).to be true
    end

    it 'returns false for child task' do
      expect(child_task.root?).to be false
    end
  end

  describe '#leaf?' do
    it 'returns true for task without children' do
      expect(task.leaf?).to be true
    end

    it 'returns false for task with children' do
      parent = described_class.new(id: 0, title: "Parent")
      described_class.new(id: 1, title: "Child", parent: parent)
      expect(parent.leaf?).to be false
    end
  end

  describe '#depth' do
    it 'returns 0 for root' do
      expect(parent_task.depth).to eq(0)
    end

    it 'returns 1 for direct child' do
      expect(child_task.depth).to eq(1)
    end

    it 'returns 2 for grandchild' do
      grandchild = described_class.new(id: 3, title: "Grandchild", parent: child_task)
      expect(grandchild.depth).to eq(2)
    end
  end

  describe '#ancestors' do
    let(:grandchild) { described_class.new(id: 3, title: "Grandchild", parent: child_task) }

    it 'returns empty array for root' do
      expect(parent_task.ancestors).to eq([])
    end

    it 'returns parent for direct child' do
      expect(child_task.ancestors).to eq([parent_task])
    end

    it 'returns all ancestors for grandchild' do
      expect(grandchild.ancestors).to eq([child_task, parent_task])
    end
  end

  describe '#descendants' do
    it 'returns all descendants' do
      parent = described_class.new(id: 0, title: "Parent")
      child1 = described_class.new(id: 1, title: "Child1", parent: parent)
      child2 = described_class.new(id: 2, title: "Child2", parent: parent)
      grandchild = described_class.new(id: 3, title: "Grandchild", parent: child1)

      expect(parent.descendants).to contain_exactly(child1, child2, grandchild)
    end

    it 'returns empty array for leaf' do
      expect(task.descendants).to eq([])
    end
  end

  describe '#siblings' do
    it 'returns empty array for root' do
      expect(task.siblings).to eq([])
    end

    it 'returns other children of parent' do
      parent = described_class.new(id: 0, title: "Parent")
      child1 = described_class.new(id: 1, title: "Child1", parent: parent)
      child2 = described_class.new(id: 2, title: "Child2", parent: parent)
      child3 = described_class.new(id: 3, title: "Child3", parent: parent)

      expect(child1.siblings).to contain_exactly(child2, child3)
    end
  end
end
