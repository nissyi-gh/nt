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

  describe '#colorize' do
    context 'when terminal supports colors' do
      before do
        allow(STDIN).to receive(:tty?).and_return(true)
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return(nil)
        allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return(nil)
        allow(ENV).to receive(:[]).with('TERM').and_return('xterm-256color')
      end

      it 'adds green color to text' do
        result = cli.colorize('Test', :green)
        expect(result).to eq("\e[32mTest\e[0m")
      end

      it 'adds red color to text' do
        result = cli.colorize('Test', :red)
        expect(result).to eq("\e[31mTest\e[0m")
      end

      it 'adds yellow color to text' do
        result = cli.colorize('Test', :yellow)
        expect(result).to eq("\e[33mTest\e[0m")
      end
    end

    context 'when terminal does not support colors' do
      before do
        allow(STDIN).to receive(:tty?).and_return(false)
      end

      it 'returns text without color codes' do
        result = cli.colorize('Test', :green)
        expect(result).to eq('Test')
      end
    end

    context 'when NO_COLOR environment variable is set' do
      before do
        allow(STDIN).to receive(:tty?).and_return(true)
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return('1')
        allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return(nil)
        allow(ENV).to receive(:[]).with('TERM').and_return('xterm-256color')
      end

      it 'returns text without color codes' do
        result = cli.colorize('Test', :green)
        expect(result).to eq('Test')
      end
    end

    context 'when TERM is dumb' do
      before do
        allow(STDIN).to receive(:tty?).and_return(true)
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return(nil)
        allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return(nil)
        allow(ENV).to receive(:[]).with('TERM').and_return('dumb')
      end

      it 'returns text without color codes' do
        result = cli.colorize('Test', :green)
        expect(result).to eq('Test')
      end
    end
  end

  describe 'selected task display' do
    before do
      task_manager.add('Task 1')
      task_manager.add('Task 2')
      task_manager.add('Task 3')

      allow(cli).to receive(:clear_screen)
      allow(cli).to receive(:terminal_size).and_return([24, 80])
      allow(STDIN).to receive(:tty?).and_return(true)
      allow(ENV).to receive(:[]).with('NO_COLOR').and_return(nil)
      allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return(nil)
      allow(ENV).to receive(:[]).with('TERM').and_return('xterm-256color')
    end

    it 'displays selected task in green when in navigation mode' do
      cli.instance_variable_set(:@mode, :navigation)
      cli.instance_variable_set(:@selected_index, 1)

      # Allow all puts calls and capture output
      output = []
      allow(cli).to receive(:puts) do |arg|
        output << (arg || "")
      end

      cli.send(:display_tasks)

      # Check that Task 2 is displayed with green color
      task2_lines = output.select { |line| line.include?('Task 2') }
      expect(task2_lines).not_to be_empty
      expect(task2_lines.first).to match(/\e\[32m.*Task 2.*\e\[0m/)
    end

    it 'does not colorize when not in navigation mode' do
      cli.instance_variable_set(:@mode, :command)
      cli.instance_variable_set(:@selected_index, 1)

      # Allow all puts calls and capture output
      output = []
      allow(cli).to receive(:puts) do |arg|
        output << (arg || "")
      end

      cli.send(:display_tasks)

      # Check that no green color codes are present
      task_lines = output.select { |line| line.include?('Task') }
      expect(task_lines).not_to be_empty
      task_lines.each do |line|
        expect(line).not_to match(/\e\[32m/)
      end
    end
  end
end
