require 'date'
require 'tempfile'

RSpec.describe NT::TaskManager do
  let(:temp_db) { Tempfile.new(['test_tasks', '.db']) }
  let(:manager) { described_class.new(db_path: temp_db.path) }

  after do
    manager.close
    temp_db.close
    temp_db.unlink
  end

  describe '#initialize' do
    it 'initializes with empty tasks array' do
      expect(manager.tasks).to eq([])
    end
  end

  describe '#add' do
    context 'with valid title' do
      it 'creates a new task' do
        task = manager.add("New Task")
        expect(task).to be_a(NT::Task)
        expect(task.title).to eq("New Task")
      end

      it 'assigns sequential IDs' do
        task1 = manager.add("Task 1")
        task2 = manager.add("Task 2")
        expect(task2.id).to be > task1.id
      end

      it 'adds task to tasks array' do
        expect { manager.add("New Task") }.to change { manager.tasks.count }.by(1)
      end

      it 'returns the created task' do
        task = manager.add("New Task")
        expect(manager.tasks).to include(task)
      end
    end

    context 'with parent_id' do
      let!(:parent) { manager.add("Parent Task") }

      it 'creates a child task' do
        child = manager.add("Child Task", parent_id: parent.id)
        expect(child.parent).to eq(parent)
        expect(parent.children).to include(child)
      end

      it 'raises error for non-existent parent' do
        expect {
          manager.add("Child Task", parent_id: 999)
        }.to raise_error(ArgumentError, "Parent task not found: 999")
      end
    end

    context 'with due_date' do
      it 'creates task with due date' do
        tomorrow = Date.today + 1
        task = manager.add("Task with deadline", due_date: tomorrow)
        expect(task.due_date).to eq(tomorrow)
      end
    end

    context 'with invalid title' do
      it 'raises error for nil title' do
        expect { manager.add(nil) }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises error for empty title' do
        expect { manager.add("") }.to raise_error(ArgumentError, "Title cannot be empty")
      end

      it 'raises error for whitespace-only title' do
        expect { manager.add("   ") }.to raise_error(ArgumentError, "Title cannot be empty")
      end
    end
  end

  describe '#find_task' do
    let!(:task) { manager.add("Test Task") }

    it 'finds task by ID' do
      found = manager.find_task(task.id)
      expect(found).to eq(task)
    end

    it 'returns nil for non-existent ID' do
      expect(manager.find_task(999)).to be_nil
    end

    it 'returns nil for nil ID' do
      expect(manager.find_task(nil)).to be_nil
    end
  end

  describe '#root_tasks' do
    it 'returns only root tasks' do
      parent1 = manager.add("Parent 1")
      parent2 = manager.add("Parent 2")
      manager.add("Child", parent_id: parent1.id)

      expect(manager.root_tasks).to contain_exactly(parent1, parent2)
    end
  end

  describe '#delete' do
    context 'with existing task' do
      let!(:task) { manager.add("Task to delete") }

      it 'removes task from tasks array' do
        expect { manager.delete(task.id) }.to change { manager.tasks.count }.by(-1)
      end

      it 'returns true' do
        expect(manager.delete(task.id)).to be true
      end
    end

    context 'with parent-child structure' do
      let!(:parent) { manager.add("Parent") }
      let!(:child) { manager.add("Child", parent_id: parent.id) }
      let!(:grandchild) { manager.add("Grandchild", parent_id: child.id) }

      it 'deletes task and all descendants' do
        manager.delete(parent.id)
        expect(manager.tasks).to be_empty
      end

      it 'removes child from parent when deleting child' do
        manager.delete(child.id)
        expect(parent.children).to be_empty
      end
    end

    context 'with non-existent task' do
      it 'returns false' do
        expect(manager.delete(999)).to be false
      end
    end
  end

  describe '#complete' do
    let!(:task) { manager.add("Task to complete") }

    context 'with existing task' do
      it 'marks task as completed' do
        manager.complete(task.id)
        expect(task.completed?).to be true
      end

      it 'returns true' do
        expect(manager.complete(task.id)).to be true
      end
    end

    context 'with non-existent task' do
      it 'returns false' do
        expect(manager.complete(999)).to be false
      end
    end
  end

  describe '#edit_title' do
    let!(:task) { manager.add("Original Title") }

    context 'with valid new title' do
      it 'updates task title' do
        manager.edit_title(task.id, "New Title")
        expect(task.title).to eq("New Title")
      end

      it 'returns true' do
        expect(manager.edit_title(task.id, "New Title")).to be true
      end
    end

    context 'with invalid new title' do
      it 'raises error for empty title' do
        expect {
          manager.edit_title(task.id, "")
        }.to raise_error(ArgumentError, "Title cannot be empty")
      end
    end

    context 'with non-existent task' do
      it 'returns false' do
        expect(manager.edit_title(999, "New Title")).to be false
      end
    end
  end

  describe '#edit_due_date' do
    let!(:task) { manager.add("Task") }
    let(:tomorrow) { Date.today + 1 }

    context 'with existing task' do
      it 'updates task due date' do
        manager.edit_due_date(task.id, tomorrow)
        expect(task.due_date).to eq(tomorrow)
      end

      it 'returns true' do
        expect(manager.edit_due_date(task.id, tomorrow)).to be true
      end

      it 'can set due date to nil' do
        manager.edit_due_date(task.id, tomorrow)
        manager.edit_due_date(task.id, nil)
        expect(task.due_date).to be_nil
      end
    end

    context 'with non-existent task' do
      it 'returns false' do
        expect(manager.edit_due_date(999, tomorrow)).to be false
      end
    end
  end

  describe '#overdue_tasks' do
    let(:yesterday) { Date.today - 1 }
    let(:tomorrow) { Date.today + 1 }

    it 'returns only overdue tasks' do
      overdue = manager.add("Overdue", due_date: yesterday)
      manager.add("Future", due_date: tomorrow)
      manager.add("No date")

      expect(manager.overdue_tasks).to contain_exactly(overdue)
    end
  end

  describe '#tasks_due_today' do
    let(:today) { Date.today }
    let(:tomorrow) { Date.today + 1 }

    it 'returns only tasks due today' do
      today_task = manager.add("Today", due_date: today)
      manager.add("Tomorrow", due_date: tomorrow)
      manager.add("No date")

      expect(manager.tasks_due_today).to contain_exactly(today_task)
    end
  end

  describe '#tasks_due_soon' do
    let(:today) { Date.today }

    it 'returns tasks due within specified days' do
      today_task = manager.add("Today", due_date: today)
      in_3_days = manager.add("In 3 days", due_date: today + 3)
      manager.add("In 4 days", due_date: today + 4)

      expect(manager.tasks_due_soon(3)).to contain_exactly(today_task, in_3_days)
    end
  end

  describe '#statistics' do
    it 'returns task statistics' do
      task1 = manager.add("Task 1")
      manager.add("Task 2", due_date: Date.today - 1)
      manager.add("Task 3", due_date: Date.today)

      manager.complete(task1.id)

      stats = manager.statistics
      expect(stats[:total]).to eq(3)
      expect(stats[:completed]).to eq(1)
      expect(stats[:incomplete]).to eq(2)
      expect(stats[:overdue]).to eq(1)
      expect(stats[:due_today]).to eq(1)
    end
  end
end
