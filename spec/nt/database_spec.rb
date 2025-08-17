require 'tempfile'
require 'fileutils'

RSpec.describe NT::Database do
  let(:temp_db) { Tempfile.new(['test_tasks', '.db']) }
  let(:db) { described_class.new(db_path: temp_db.path) }

  after do
    db.close
    temp_db.close
    temp_db.unlink
  end

  describe '#initialize' do
    it 'creates a database file' do
      expect(File.exist?(temp_db.path)).to be true
    end

    it 'creates the tasks table' do
      result = db.db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'")
      expect(result).not_to be_empty
    end
  end

  describe '#insert_task' do
    let(:task) { NT::Task.new(id: 1, title: "Test Task", due_date: Date.today) }

    it 'inserts a new task' do
      id = db.insert_task(task)
      expect(id).to be_a(Integer)
      expect(id).to be > 0
    end

    it 'stores task attributes correctly' do
      id = db.insert_task(task)
      result = db.db.get_first_row("SELECT * FROM tasks WHERE id = ?", [id])

      expect(result['title']).to eq("Test Task")
      expect(result['completed']).to eq(0)
      expect(result['due_date']).to eq(Date.today.to_s)
    end

    context 'with parent task' do
      let(:parent) { NT::Task.new(id: 1, title: "Parent") }
      let(:child) { NT::Task.new(id: 2, title: "Child", parent: parent) }

      it 'stores parent relationship' do
        parent_id = db.insert_task(parent)
        parent.instance_variable_set(:@id, parent_id)

        child_id = db.insert_task(child)
        result = db.db.get_first_row("SELECT * FROM tasks WHERE id = ?", [child_id])

        expect(result['parent_id']).to eq(parent_id)
      end
    end
  end

  describe '#update_task' do
    let(:task) { NT::Task.new(id: 1, title: "Original Title") }

    before do
      id = db.insert_task(task)
      task.instance_variable_set(:@id, id)
    end

    it 'updates task attributes' do
      task.update_title("New Title")
      task.complete!

      db.update_task(task)

      result = db.db.get_first_row("SELECT * FROM tasks WHERE id = ?", [task.id])
      expect(result['title']).to eq("New Title")
      expect(result['completed']).to eq(1)
    end
  end

  describe '#delete_task' do
    let(:task) { NT::Task.new(id: 1, title: "Task to Delete") }

    it 'deletes the task' do
      id = db.insert_task(task)
      db.delete_task(id)

      result = db.find_task(id)
      expect(result).to be_nil
    end
  end

  describe '#find_task' do
    let(:task) { NT::Task.new(id: 1, title: "Find Me") }

    it 'finds existing task' do
      id = db.insert_task(task)

      found = db.find_task(id)
      expect(found).not_to be_nil
      expect(found.title).to eq("Find Me")
    end

    it 'returns nil for non-existent task' do
      expect(db.find_task(999)).to be_nil
    end
  end

  describe '#all_tasks' do
    it 'returns empty array when no tasks' do
      expect(db.all_tasks).to eq([])
    end

    it 'returns all tasks' do
      3.times { |i| db.insert_task(NT::Task.new(id: i+1, title: "Task #{i+1}")) }

      tasks = db.all_tasks
      expect(tasks.count).to eq(3)
      expect(tasks.map(&:title)).to contain_exactly("Task 1", "Task 2", "Task 3")
    end

    it 'preserves parent-child relationships' do
      parent = NT::Task.new(id: 1, title: "Parent")
      parent_id = db.insert_task(parent)
      parent.instance_variable_set(:@id, parent_id)

      child = NT::Task.new(id: 2, title: "Child", parent: parent)
      db.insert_task(child)

      tasks = db.all_tasks
      parent_task = tasks.find { |t| t.title == "Parent" }
      child_task = tasks.find { |t| t.title == "Child" }

      expect(parent_task.children).to include(child_task)
      expect(child_task.parent).to eq(parent_task)
    end
  end

  describe '#task_exists?' do
    it 'returns true for existing task' do
      id = db.insert_task(NT::Task.new(id: 1, title: "Exists"))
      expect(db.task_exists?(id)).to be true
    end

    it 'returns false for non-existent task' do
      expect(db.task_exists?(999)).to be false
    end
  end

  describe '#clear_all' do
    it 'removes all tasks' do
      3.times { |i| db.insert_task(NT::Task.new(id: i+1, title: "Task #{i+1}")) }

      db.clear_all
      expect(db.all_tasks).to be_empty
    end
  end
end
