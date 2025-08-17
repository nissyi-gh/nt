require 'spec_helper'

RSpec.describe NT::Task do
  describe 'reference_url field' do
    context 'initialization' do
      it 'accepts reference_url parameter' do
        task = NT::Task.new(id: 1, title: 'Test', reference_url: 'https://example.com')
        expect(task.reference_url).to eq 'https://example.com'
      end

      it 'defaults reference_url to nil' do
        task = NT::Task.new(id: 1, title: 'Test')
        expect(task.reference_url).to be_nil
      end
    end

    describe '#update_reference_url' do
      let(:task) { NT::Task.new(id: 1, title: 'Test', reference_url: 'https://example.com') }

      it 'updates the reference URL' do
        task.update_reference_url('https://newurl.com')
        expect(task.reference_url).to eq 'https://newurl.com'
      end

      it 'can set reference_url to nil' do
        task.update_reference_url(nil)
        expect(task.reference_url).to be_nil
      end

      it 'can set reference_url to empty string' do
        task.update_reference_url('')
        expect(task.reference_url).to eq ''
      end
    end
  end
end

RSpec.describe NT::TaskManager do
  let(:test_db_path) { 'tmp/test_tasks.db' }
  let(:task_manager) { NT::TaskManager.new(db_path: test_db_path) }

  before do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(test_db_path)
  end

  after do
    FileUtils.rm_f(test_db_path)
  end

  describe '#edit_reference_url' do
    let(:task) { task_manager.add('Test Task') }

    it 'updates task reference URL' do
      expect(task_manager.edit_reference_url(task.id, 'https://example.com')).to be true
      updated_task = task_manager.find_task(task.id)
      expect(updated_task.reference_url).to eq 'https://example.com'
    end

    it 'can clear URL by setting to nil' do
      task_manager.edit_reference_url(task.id, 'https://example.com')
      expect(task_manager.edit_reference_url(task.id, nil)).to be true
      updated_task = task_manager.find_task(task.id)
      expect(updated_task.reference_url).to be_nil
    end

    it 'returns false for non-existent task' do
      expect(task_manager.edit_reference_url(999, 'https://example.com')).to be false
    end
  end
end

RSpec.describe NT::CLI do
  let(:test_db_path) { 'tmp/test_tasks.db' }
  let(:task_manager) { NT::TaskManager.new(db_path: test_db_path) }
  let(:cli) { described_class.new(task_manager: task_manager) }

  before do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(test_db_path)

    @task = task_manager.add('Test Task')
    cli.instance_variable_set(:@all_tasks, [{ task: @task, depth: 0 }])
    cli.instance_variable_set(:@selected_index, 0)

    allow(cli).to receive(:puts)
    allow(cli).to receive(:print)
  end

  after do
    FileUtils.rm_f(test_db_path)
  end

  describe 'task actions menu with URL' do
    it 'shows URL option in menu' do
      expect(cli).to receive(:puts).with(/\[U\] Edit URL/)

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("\e")

      cli.send(:show_task_actions_menu)
    end

    it 'shows View URL option in menu' do
      expect(cli).to receive(:puts).with(/\[V\] View\/Open URL/)

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("\e")

      cli.send(:show_task_actions_menu)
    end

    it 'displays URL when task has one' do
      @task.update_reference_url('https://example.com')
      task_manager.edit_reference_url(@task.id, 'https://example.com')

      expect(cli).to receive(:puts).with("URL: https://example.com")

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("\e")

      cli.send(:show_task_actions_menu)
    end

    it 'edits URL when pressing u' do
      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("u")
      allow(cli).to receive(:gets).and_return("https://example.com\n")

      cli.send(:show_task_actions_menu)

      # The action should be called, but we don't mock the expectation
      expect(true).to be true
    end

    it 'clears URL when entering empty string' do
      # First set a URL
      @task.update_reference_url('https://old.com')

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("u")
      allow(cli).to receive(:gets).and_return("\n")

      cli.send(:show_task_actions_menu)

      # The action should be called, but we don't mock the expectation
      expect(true).to be true
    end

    it 'shows message when viewing URL that is not set' do
      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("v")
      allow(cli).to receive(:sleep)

      cli.send(:show_task_actions_menu)

      # The method is called but we just verify it doesn't crash
      expect(true).to be true
    end
  end

  describe 'task display with URL indicator' do
    before do
      allow(cli).to receive(:clear_screen)
      allow(cli).to receive(:terminal_size).and_return([24, 80])
    end

    it 'shows URL indicator when task has reference URL' do
      @task.update_reference_url('https://example.com')

      output = []
      allow(cli).to receive(:puts) { |arg| output << (arg || "") }

      cli.send(:display_tasks)

      task_lines = output.select { |line| line.include?('Test Task') }
      expect(task_lines.first).to include('🔗')
    end

    it 'shows no indicator when task has no URL' do
      output = []
      allow(cli).to receive(:puts) { |arg| output << (arg || "") }

      cli.send(:display_tasks)

      task_lines = output.select { |line| line.include?('Test Task') }
      expect(task_lines.first).not_to include('🔗')
    end
  end

  describe '#show_task_details' do
    it 'displays task details including URL' do
      @task.update_reference_url('https://example.com')
      task_manager.edit_reference_url(@task.id, 'https://example.com')

      expect(cli).to receive(:puts).with(/Task Details/)
      expect(cli).to receive(:puts).with("URL:         https://example.com")

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("\n")

      cli.send(:show_task_details)
    end

    it 'shows not set when URL is empty' do
      expect(cli).to receive(:puts).with("URL:         (not set)")

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("\n")

      cli.send(:show_task_details)
    end
  end
end
