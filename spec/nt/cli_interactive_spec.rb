require 'tempfile'

RSpec.describe NT::CLI do
  let(:temp_db) { Tempfile.new(['test_cli_interactive', '.db']) }
  let(:task_manager) { NT::TaskManager.new(db_path: temp_db.path) }
  let(:cli) { described_class.new(task_manager: task_manager) }

  before do
    allow(cli).to receive(:puts)
    allow(cli).to receive(:print)
    allow(cli).to receive(:sleep)
    allow(cli).to receive(:system).with("clear")
    allow(STDIN).to receive(:tty?).and_return(true)

    # Add some test tasks
    @task1 = task_manager.add("Task 1")
    @task2 = task_manager.add("Task 2", parent_id: @task1.id)
    @task3 = task_manager.add("Task 3")
    @task67 = nil
    # Create tasks until we have ID 67
    64.times { |i| task_manager.add("Task #{i + 4}") }
    @task67 = task_manager.find_task(67)
  end

  after do
    task_manager.close
    temp_db.close
    temp_db.unlink
  end

  describe 'interactive navigation mode' do
    describe '#initialize' do
      it 'starts in navigation mode' do
        expect(cli.instance_variable_get(:@mode)).to eq(:navigation)
      end

      it 'initializes selected_index to 0' do
        expect(cli.instance_variable_get(:@selected_index)).to eq(0)
      end

      it 'initializes empty ID buffer' do
        expect(cli.instance_variable_get(:@id_buffer)).to eq("")
      end

      it 'initializes empty all_tasks array' do
        expect(cli.instance_variable_get(:@all_tasks)).to eq([])
      end
    end

    describe '#collect_all_tasks' do
      it 'flattens hierarchical tasks into a list' do
        tasks = cli.send(:collect_all_tasks, task_manager.root_tasks)
        expect(tasks).to be_an(Array)
        expect(tasks.length).to be > 0

        # Check structure
        tasks.each do |task_info|
          expect(task_info).to have_key(:task)
          expect(task_info).to have_key(:depth)
          expect(task_info[:task]).to be_a(NT::Task)
          expect(task_info[:depth]).to be >= 0
        end
      end

      it 'preserves parent-child depth relationships' do
        tasks = cli.send(:collect_all_tasks, task_manager.root_tasks)

        task1_info = tasks.find { |t| t[:task].id == @task1.id }
        task2_info = tasks.find { |t| t[:task].id == @task2.id }

        expect(task1_info[:depth]).to eq(0)
        expect(task2_info[:depth]).to eq(1)
      end
    end

    describe '#handle_navigation_input' do
      before do
        cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))
      end

      context 'with arrow keys' do
        it 'moves selection down with down arrow' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\e")
          allow(STDIN).to receive(:read_nonblock).and_return("[B")

          initial_index = cli.instance_variable_get(:@selected_index)
          cli.send(:handle_navigation_input)
          new_index = cli.instance_variable_get(:@selected_index)

          expect(new_index).to eq(initial_index + 1)
        end

        it 'moves selection up with up arrow' do
          cli.instance_variable_set(:@selected_index, 2)

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\e")
          allow(STDIN).to receive(:read_nonblock).and_return("[A")

          initial_index = cli.instance_variable_get(:@selected_index)
          cli.send(:handle_navigation_input)
          new_index = cli.instance_variable_get(:@selected_index)

          expect(new_index).to eq(initial_index - 1)
        end

        it 'does not move beyond first task' do
          cli.instance_variable_set(:@selected_index, 0)

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\e")
          allow(STDIN).to receive(:read_nonblock).and_return("[A")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@selected_index)).to eq(0)
        end

        it 'does not move beyond last task' do
          last_index = cli.instance_variable_get(:@all_tasks).length - 1
          cli.instance_variable_set(:@selected_index, last_index)

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\e")
          allow(STDIN).to receive(:read_nonblock).and_return("[B")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@selected_index)).to eq(last_index)
        end
      end

      context 'with ID input' do
        it 'accumulates digits in ID buffer' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("6")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("6")

          allow(STDIN).to receive(:getch).and_return("7")
          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("67")
        end

        it 'jumps to task when Enter is pressed with ID buffer' do
          cli.instance_variable_set(:@id_buffer, "67")

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\r")

          cli.send(:handle_navigation_input)

          selected_index = cli.instance_variable_get(:@selected_index)
          selected_task = cli.instance_variable_get(:@all_tasks)[selected_index][:task]

          expect(selected_task.id).to eq(67)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        end

        it 'clears ID buffer on invalid input' do
          cli.instance_variable_set(:@id_buffer, "12")

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("a")
          allow(cli).to receive(:add_task_interactive)

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        end

        it 'handles backspace in ID buffer' do
          cli.instance_variable_set(:@id_buffer, "123")

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\x7f")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("12")
        end

        it 'clears ID buffer on Ctrl-C' do
          cli.instance_variable_set(:@id_buffer, "123")

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\x03")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        end

        it 'processes ID buffer after timeout' do
          cli.instance_variable_set(:@id_buffer, "3")
          cli.instance_variable_set(:@id_input_time, Time.now - 2) # 2 seconds ago

          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("q")

          cli.send(:handle_navigation_input)

          selected_index = cli.instance_variable_get(:@selected_index)
          selected_task = cli.instance_variable_get(:@all_tasks)[selected_index][:task]

          expect(selected_task.id).to eq(3)
          expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        end
      end

      context 'with command keys' do
        it 'quits on q key' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("q")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@running)).to be false
        end

        it 'switches to command mode on / key' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("/")

          cli.send(:handle_navigation_input)
          expect(cli.instance_variable_get(:@mode)).to eq(:command)
        end

        it 'calls add_task_interactive on a key' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("a")
          expect(cli).to receive(:add_task_interactive)

          cli.send(:handle_navigation_input)
        end

        it 'shows task actions menu on Enter with tasks' do
          allow(STDIN).to receive(:raw).and_yield(STDIN)
          allow(STDIN).to receive(:getch).and_return("\r")
          expect(cli).to receive(:show_task_actions_menu)

          cli.send(:handle_navigation_input)
        end
      end
    end

    describe '#process_id_buffer' do
      before do
        cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))
      end

      it 'jumps to task with matching ID' do
        cli.instance_variable_set(:@id_buffer, "3")

        cli.send(:process_id_buffer)

        selected_index = cli.instance_variable_get(:@selected_index)
        selected_task = cli.instance_variable_get(:@all_tasks)[selected_index][:task]

        expect(selected_task.id).to eq(3)
      end

      it 'does nothing with empty buffer' do
        cli.instance_variable_set(:@id_buffer, "")
        initial_index = cli.instance_variable_get(:@selected_index)

        cli.send(:process_id_buffer)

        expect(cli.instance_variable_get(:@selected_index)).to eq(initial_index)
      end

      it 'does nothing with non-existent ID' do
        cli.instance_variable_set(:@id_buffer, "9999")
        initial_index = cli.instance_variable_get(:@selected_index)

        cli.send(:process_id_buffer)

        expect(cli.instance_variable_get(:@selected_index)).to eq(initial_index)
      end

      it 'clears buffer after processing' do
        cli.instance_variable_set(:@id_buffer, "3")

        cli.send(:process_id_buffer)

        expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        expect(cli.instance_variable_get(:@id_input_time)).to be_nil
      end
    end

    describe '#clear_id_buffer' do
      it 'clears the ID buffer and timer' do
        cli.instance_variable_set(:@id_buffer, "123")
        cli.instance_variable_set(:@id_input_time, Time.now)

        cli.send(:clear_id_buffer)

        expect(cli.instance_variable_get(:@id_buffer)).to eq("")
        expect(cli.instance_variable_get(:@id_input_time)).to be_nil
      end
    end

    describe '#display_tasks_with_selection' do
      before do
        cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))
      end

      it 'displays tasks with selection indicator' do
        cli.instance_variable_set(:@selected_index, 1)

        expect(cli).to receive(:puts).at_least(:once)
        cli.send(:display_tasks_with_selection, 10)
      end

      it 'handles empty task list' do
        cli.instance_variable_set(:@all_tasks, [])

        expect { cli.send(:display_tasks_with_selection, 10) }.not_to raise_error
      end

      it 'shows scroll indicator for long lists' do
        expect(cli).to receive(:puts).with(/more tasks below/).at_least(:once)
        cli.send(:display_tasks_with_selection, 5)
      end
    end

    describe '#show_navigation_prompt' do
      it 'shows ID buffer when typing' do
        cli.instance_variable_set(:@id_buffer, "67")
        cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))

        expect(cli).to receive(:puts).with(/Typing ID: 67/)
        cli.send(:show_navigation_prompt)
      end

      it 'shows navigation instructions' do
        cli.instance_variable_set(:@all_tasks, cli.send(:collect_all_tasks, task_manager.root_tasks))

        expect(cli).to receive(:puts).with(/Navigate.*Actions.*Details.*Add.*Export.*Cmd.*Quit/)
        cli.send(:show_navigation_prompt)
      end
    end
  end
end
