require 'tempfile'

RSpec.describe NT::CLI do
  let(:temp_db) { Tempfile.new(['test_cli_actions', '.db']) }
  let(:task_manager) { NT::TaskManager.new(db_path: temp_db.path) }
  let(:cli) { described_class.new(task_manager: task_manager) }

  before do
    allow(cli).to receive(:puts)
    allow(cli).to receive(:print)
    allow(cli).to receive(:sleep)
    allow(STDIN).to receive(:tty?).and_return(true)

    # Add test tasks
    @task1 = task_manager.add("Test Task 1", due_date: Date.today + 7)
    @task2 = task_manager.add("Test Task 2")
    @task3 = task_manager.add("Child Task", parent_id: @task1.id)

    # Set up for action menu
    cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))
    cli.instance_variable_set(:@selected_index, 0)
  end

  after do
    task_manager.close
    temp_db.close
    temp_db.unlink
  end

  describe '#show_task_actions_menu' do
    it 'displays the action menu' do
      expect(cli).to receive(:puts).with(/Task: Test Task 1/)
      expect(cli).to receive(:puts).with(/\[C\] Complete\/Uncomplete/)
      expect(cli).to receive(:puts).with(/\[E\] Edit title/)
      expect(cli).to receive(:puts).with(/\[D\] Set due date/)
      expect(cli).to receive(:puts).with(/\[U\] Edit URL/)
      expect(cli).to receive(:puts).with(/\[V\] View\/Open URL/)
      expect(cli).to receive(:puts).with(/\[A\] Add child task/)
      expect(cli).to receive(:puts).with(/\[X\] Delete task/)
      expect(cli).to receive(:puts).with(/\[ESC\] Cancel/)
      expect(cli).to receive(:print).with("Choose action: ")

      allow(STDIN).to receive(:raw).and_yield(STDIN)
      allow(STDIN).to receive(:getch).and_return("0")

      cli.send(:show_task_actions_menu)
    end

    context 'action selection' do
      it 'completes task when selecting 1 for incomplete task' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("1")

        expect(task_manager).to receive(:complete).with(@task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'uncompletes task when selecting 1 for completed task' do
        @task1.complete!

        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("1")

        expect(task_manager).to receive(:uncomplete).with(@task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'edits title when selecting 2' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("2")
        allow(cli).to receive(:gets).and_return("New Title\n")

        expect(task_manager).to receive(:edit_title).with(@task1.id, "New Title")

        cli.send(:show_task_actions_menu)
      end

      it 'sets due date when selecting 3' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("3")
        allow(cli).to receive(:gets).and_return("tomorrow\n")

        expect(task_manager).to receive(:edit_due_date).with(@task1.id, Date.today + 1)

        cli.send(:show_task_actions_menu)
      end

      it 'adds child task when selecting 4' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("4")
        allow(cli).to receive(:gets).and_return("New Child Task\n")

        expect(task_manager).to receive(:add).with("New Child Task", parent_id: @task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'deletes task when selecting 5 and confirming' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("5", "y")

        expect(task_manager).to receive(:delete).with(@task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'does not delete task when selecting 5 and canceling' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("5", "n")

        expect(task_manager).not_to receive(:delete)

        cli.send(:show_task_actions_menu)
      end

      it 'completes task when pressing c' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("c")

        expect(task_manager).to receive(:complete).with(@task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'edits title when pressing e' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("e")
        allow(cli).to receive(:gets).and_return("New Title\n")

        expect(task_manager).to receive(:edit_title).with(@task1.id, "New Title")

        cli.send(:show_task_actions_menu)
      end

      it 'sets due date when pressing d' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("d")
        allow(cli).to receive(:gets).and_return("tomorrow\n")

        expect(task_manager).to receive(:edit_due_date).with(@task1.id, Date.today + 1)

        cli.send(:show_task_actions_menu)
      end

      it 'adds child task when pressing a' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("a")
        allow(cli).to receive(:gets).and_return("New Child Task\n")

        expect(task_manager).to receive(:add).with("New Child Task", parent_id: @task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'deletes task when pressing x and confirming' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("x", "y")

        expect(task_manager).to receive(:delete).with(@task1.id)

        cli.send(:show_task_actions_menu)
      end

      it 'cancels menu when selecting 0' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("0")

        expect(task_manager).not_to receive(:complete)
        expect(task_manager).not_to receive(:edit_title)
        expect(task_manager).not_to receive(:edit_due_date)
        expect(task_manager).not_to receive(:add)
        expect(task_manager).not_to receive(:delete)

        cli.send(:show_task_actions_menu)
      end

      it 'cancels menu when pressing ESC' do
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("\e")

        expect(task_manager).not_to receive(:complete)
        expect(task_manager).not_to receive(:edit_title)
        expect(task_manager).not_to receive(:edit_due_date)
        expect(task_manager).not_to receive(:add)
        expect(task_manager).not_to receive(:delete)

        cli.send(:show_task_actions_menu)
      end
    end

    context 'with no selected task' do
      it 'returns without showing menu when no task selected' do
        cli.instance_variable_set(:@all_tasks, [])

        expect(cli).not_to receive(:print).with("Choose action: ")

        cli.send(:show_task_actions_menu)
      end
    end
  end

  describe '#add_task_interactive' do
    it 'adds a task with the provided title' do
      allow(cli).to receive(:print).with("\nTask title: ")
      allow(cli).to receive(:gets).and_return("New Task Title\n")

      expect(task_manager).to receive(:add).with("New Task Title")
      expect(cli).to receive(:puts).with("Task added successfully!")

      cli.send(:add_task_interactive)
    end

    it 'does nothing with empty title' do
      allow(cli).to receive(:print).with("\nTask title: ")
      allow(cli).to receive(:gets).and_return("\n")

      expect(task_manager).not_to receive(:add)

      cli.send(:add_task_interactive)
    end
  end

  describe '#get_single_char' do
    context 'when STDIN is a TTY' do
      it 'uses raw mode to get character' do
        allow(STDIN).to receive(:tty?).and_return(true)
        allow(STDIN).to receive(:raw).and_yield(STDIN)
        allow(STDIN).to receive(:getch).and_return("a")

        expect(cli.send(:get_single_char)).to eq("a")
      end
    end

    context 'when STDIN is not a TTY' do
      it 'uses getc as fallback' do
        allow(STDIN).to receive(:tty?).and_return(false)
        allow(STDIN).to receive(:getc).and_return("b")

        expect(cli.send(:get_single_char)).to eq("b")
      end
    end
  end
end
