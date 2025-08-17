require 'spec_helper'
require 'date'

RSpec.describe NT::CLI do
  let(:test_db_path) { 'tmp/test_tasks.db' }
  let(:task_manager) { NT::TaskManager.new(db_path: test_db_path) }
  let(:cli) { described_class.new(task_manager: task_manager) }

  before do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f(test_db_path)

    # Setup color support
    allow(cli).to receive(:clear_screen)
    allow(cli).to receive(:terminal_size).and_return([24, 80])
    allow(STDIN).to receive(:tty?).and_return(true)
    allow(ENV).to receive(:[]).with('NO_COLOR').and_return(nil)
    allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return(nil)
    allow(ENV).to receive(:[]).with('TERM').and_return('xterm-256color')
  end

  after do
    FileUtils.rm_f(test_db_path)
  end

  describe 'due date color coding' do
    let(:output) { [] }

    before do
      allow(cli).to receive(:puts) do |arg|
        output << (arg || "")
      end
    end

    context 'with overdue tasks' do
      before do
        @overdue_task = task_manager.add('Overdue Task')
        task_manager.edit_due_date(@overdue_task.id, Date.today - 3)

        @normal_task = task_manager.add('Normal Task')

        cli.instance_variable_set(:@mode, :command)  # Not in navigation mode
      end

      it 'displays overdue tasks in red' do
        cli.send(:display_tasks)

        overdue_lines = output.select { |line| line.include?('Overdue Task') }
        expect(overdue_lines).not_to be_empty
        expect(overdue_lines.first).to match(/\e\[31m.*Overdue Task.*\e\[0m/)
      end

      it 'does not color completed overdue tasks' do
        task_manager.complete(@overdue_task.id)
        output.clear

        cli.send(:display_tasks)

        overdue_lines = output.select { |line| line.include?('Overdue Task') }
        expect(overdue_lines).not_to be_empty
        expect(overdue_lines.first).not_to match(/\e\[31m/)
      end

      it 'does not color normal tasks' do
        cli.send(:display_tasks)

        normal_lines = output.select { |line| line.include?('Normal Task') }
        expect(normal_lines).not_to be_empty
        expect(normal_lines.first).not_to match(/\e\[\d+m/)  # No color codes
      end
    end

    context 'with tasks due soon' do
      before do
        @soon_task = task_manager.add('Due Soon Task')
        task_manager.edit_due_date(@soon_task.id, Date.today + 2)  # Due in 2 days

        @future_task = task_manager.add('Future Task')
        task_manager.edit_due_date(@future_task.id, Date.today + 10)  # Due in 10 days

        cli.instance_variable_set(:@mode, :command)
      end

      it 'displays tasks due soon in yellow' do
        cli.send(:display_tasks)

        soon_lines = output.select { |line| line.include?('Due Soon Task') }
        expect(soon_lines).not_to be_empty
        expect(soon_lines.first).to match(/\e\[33m.*Due Soon Task.*\e\[0m/)
      end

      it 'does not color tasks due far in the future' do
        cli.send(:display_tasks)

        future_lines = output.select { |line| line.include?('Future Task') }
        expect(future_lines).not_to be_empty
        expect(future_lines.first).not_to match(/\e\[\d+m/)
      end

      it 'does not color completed tasks due soon' do
        task_manager.complete(@soon_task.id)
        output.clear

        cli.send(:display_tasks)

        soon_lines = output.select { |line| line.include?('Due Soon Task') }
        expect(soon_lines).not_to be_empty
        expect(soon_lines.first).not_to match(/\e\[33m/)
      end
    end

    context 'with selected task overriding due date colors' do
      before do
        @overdue_task = task_manager.add('Overdue Selected')
        task_manager.edit_due_date(@overdue_task.id, Date.today - 1)

        cli.instance_variable_set(:@mode, :navigation)
        cli.instance_variable_set(:@selected_index, 0)
      end

      it 'shows selected task in green even if overdue' do
        cli.send(:display_tasks)

        selected_lines = output.select { |line| line.include?('Overdue Selected') }
        expect(selected_lines).not_to be_empty
        # Should be green (selected), not red (overdue)
        expect(selected_lines.first).to match(/\e\[32m.*Overdue Selected.*\e\[0m/)
        expect(selected_lines.first).not_to match(/\e\[31m/)  # Not red
      end
    end

    context 'with tasks due today' do
      before do
        @today_task = task_manager.add('Due Today Task')
        task_manager.edit_due_date(@today_task.id, Date.today)

        cli.instance_variable_set(:@mode, :command)
      end

      it 'displays tasks due today in yellow' do
        cli.send(:display_tasks)

        today_lines = output.select { |line| line.include?('Due Today Task') }
        expect(today_lines).not_to be_empty
        expect(today_lines.first).to match(/\e\[33m.*Due Today Task.*\e\[0m/)
      end
    end
  end
end
