RSpec.describe NT::CLI do
  let(:cli) { described_class.new }
  let(:task_manager) { instance_double(NT::TaskManager) }

  before do
    allow(cli).to receive(:puts)
    allow(cli).to receive(:print)
    allow(cli).to receive(:sleep)
    cli.instance_variable_set(:@task_manager, task_manager)
  end

  describe '#add_child_task (private)' do
    let(:parent_task) { NT::Task.new(id: 1, title: "Parent") }
    let(:child_task) { NT::Task.new(id: 2, title: "Child", parent: parent_task) }

    context 'with valid parent_id and title' do
      it 'adds a child task to the specified parent' do
        expect(task_manager).to receive(:add)
          .with("Child task", parent_id: 1)
          .and_return(child_task)
        expect(cli).to receive(:puts).with("Added child task: #{child_task.to_s}")

        cli.send(:add_child_task, 1, "Child task")
      end
    end

    context 'when parent_id is nil' do
      it 'shows error message' do
        expect(cli).to receive(:puts)
          .with("Error: Parent ID is required. Usage: add-child <parent_id> <title>")
        expect(task_manager).not_to receive(:add)

        cli.send(:add_child_task, nil, "Child task")
      end
    end

    context 'when title is nil' do
      it 'shows error message' do
        expect(cli).to receive(:puts)
          .with("Error: Title is required. Usage: add-child <parent_id> <title>")
        expect(task_manager).not_to receive(:add)

        cli.send(:add_child_task, 1, nil)
      end
    end

    context 'when title is empty' do
      it 'shows error message' do
        expect(cli).to receive(:puts)
          .with("Error: Title is required. Usage: add-child <parent_id> <title>")
        expect(task_manager).not_to receive(:add)

        cli.send(:add_child_task, 1, "   ")
      end
    end

    context 'when parent task does not exist' do
      it 'shows error message' do
        expect(task_manager).to receive(:add)
          .with("Child task", parent_id: 999)
          .and_raise(ArgumentError, "Parent task not found: 999")
        expect(cli).to receive(:puts).with("Error: Parent task not found: 999")

        cli.send(:add_child_task, 999, "Child task")
      end
    end
  end

  describe '#handle_input with add-child command' do
    before do
      allow(cli).to receive(:gets).and_return("add-child 1 New child task\n")
    end

    it 'parses add-child command correctly' do
      expect(cli).to receive(:add_child_task).with(1, "New child task")
      cli.send(:handle_input)
    end

    it 'supports ac shortcut' do
      allow(cli).to receive(:gets).and_return("ac 1 New child task\n")
      expect(cli).to receive(:add_child_task).with(1, "New child task")
      cli.send(:handle_input)
    end
  end
end
