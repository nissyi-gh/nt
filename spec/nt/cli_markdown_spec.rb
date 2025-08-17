require 'spec_helper'

RSpec.describe NT::CLI do
  let(:test_db_path) { 'tmp/test_tasks.db' }
  let(:task_manager) { NT::TaskManager.new(db_path: test_db_path) }
  let(:cli) { described_class.new(task_manager: task_manager) }

  before do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(test_db_path)
  end

  after do
    FileUtils.rm_f(test_db_path)
  end

  describe '#generate_markdown' do
    context 'with no tasks' do
      it 'generates markdown with empty task list' do
        markdown = cli.send(:generate_markdown)
        expect(markdown).to include('# Task List')
        expect(markdown).to include('## Statistics')
        expect(markdown).to include('Total tasks: 0')
        expect(markdown).to include('_No tasks yet._')
      end
    end

    context 'with tasks' do
      before do
        @task1 = task_manager.add('Task 1')
        @task2 = task_manager.add('Task 2', parent_id: @task1.id)
        @task3 = task_manager.add('Task 3')
        task_manager.complete(@task2.id)
        task_manager.edit_due_date(@task1.id, Date.today)
      end

      it 'generates markdown with task hierarchy' do
        markdown = cli.send(:generate_markdown)

        expect(markdown).to include('# Task List')
        expect(markdown).to include('## Statistics')
        expect(markdown).to include('Total tasks: 3')
        expect(markdown).to include('Completed: 1')
        expect(markdown).to include('## Tasks')

        # Check task formatting
        expect(markdown).to include('- [ ] Task 1')
        expect(markdown).to include('  - [x] Task 2')  # Indented child
        expect(markdown).to include('- [ ] Task 3')

        # Check metadata
        expect(markdown).to include('**DUE TODAY**')
      end
    end

    context 'with overdue tasks' do
      before do
        @task = task_manager.add('Overdue Task')
        task_manager.edit_due_date(@task.id, Date.today - 1)
      end

      it 'marks overdue tasks appropriately' do
        markdown = cli.send(:generate_markdown)
        expect(markdown).to include('**OVERDUE:')
        expect(markdown).to include('Overdue: 1')
      end
    end
  end

  describe '#append_tasks_as_markdown' do
    before do
      @task1 = task_manager.add('Parent Task')
      @task2 = task_manager.add('Child Task', parent_id: @task1.id)
      task_manager.complete(@task2.id)
    end

    it 'appends tasks with correct indentation' do
      content = []
      cli.send(:append_tasks_as_markdown, task_manager.root_tasks, content, 0)

      expect(content[0]).to eq('- [ ] Parent Task')
      expect(content[1]).to eq('  - [x] Child Task')
    end

    it 'handles multiple levels of nesting' do
      @task3 = task_manager.add('Grandchild Task', parent_id: @task2.id)

      content = []
      cli.send(:append_tasks_as_markdown, task_manager.root_tasks, content, 0)

      expect(content[2]).to eq('    - [ ] Grandchild Task')
    end
  end

  describe '#export_to_markdown' do
    before do
      allow(cli).to receive(:clear_screen)
      allow(cli).to receive(:get_single_char).and_return('n')
      allow(cli).to receive(:puts)
      allow(cli).to receive(:print)

      task_manager.add('Test Task')
    end

    it 'displays markdown content' do
      markdown_output = nil
      allow(cli).to receive(:puts) do |arg|
        markdown_output = arg if arg.is_a?(String) && arg.include?('# Task List')
      end

      cli.export_to_markdown

      expect(markdown_output).to include('# Task List')
      expect(markdown_output).to include('- [ ] Test Task')
    end

    context 'when user chooses to save' do
      before do
        allow(cli).to receive(:get_single_char).and_return('y', nil)
        allow(cli).to receive(:gets).and_return("test_export.md\n")
      end

      it 'saves markdown to file' do
        expect(File).to receive(:write).with('test_export.md', anything)
        cli.export_to_markdown
      end

      it 'adds .md extension if not provided' do
        allow(cli).to receive(:gets).and_return("test_export\n")
        expect(File).to receive(:write).with('test_export.md', anything)
        cli.export_to_markdown
      end
    end

    context 'when user chooses not to save' do
      it 'does not save to file' do
        expect(File).not_to receive(:write)
        cli.export_to_markdown
      end
    end
  end

  describe 'navigation mode markdown export' do
    it 'exports markdown when m key is pressed' do
      allow(cli).to receive(:clear_screen)
      allow(cli).to receive(:display_tasks)
      allow(cli).to receive(:show_navigation_prompt)
      allow(cli).to receive(:get_single_char).and_return('m', 'n', 'q')
      allow(cli).to receive(:puts)
      allow(cli).to receive(:print)

      expect(cli).to receive(:export_to_markdown)

      cli.run
    end
  end
end
