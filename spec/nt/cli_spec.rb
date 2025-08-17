RSpec.describe NT::CLI do
  let(:cli) { described_class.new }

  describe '#initialize' do
    it 'sets @running to true' do
      expect(cli.instance_variable_get(:@running)).to be true
    end
  end

  describe '#run' do
    before do
      allow(cli).to receive(:clear_screen)
      allow(cli).to receive(:display_tasks)
      allow(cli).to receive(:show_prompt)
      allow(cli).to receive(:handle_input) do
        cli.instance_variable_set(:@running, false)
      end
      allow(cli).to receive(:puts)
    end

    it 'runs the main loop until @running is false' do
      expect(cli).to receive(:clear_screen).once
      expect(cli).to receive(:display_tasks).once
      expect(cli).to receive(:show_prompt).once
      expect(cli).to receive(:handle_input).once
      expect(cli).to receive(:puts).with("\nBye!")

      cli.run
    end
  end

  describe '#handle_input (private)' do
    before do
      allow(cli).to receive(:puts)
      allow(cli).to receive(:print)
      allow(cli).to receive(:sleep)
    end

    context 'when input is "exit"' do
      it 'sets @running to false' do
        allow(cli).to receive(:gets).and_return("exit\n")

        cli.send(:handle_input)

        expect(cli.instance_variable_get(:@running)).to be false
      end
    end

    context 'when input is empty' do
      it 'returns without error' do
        allow(cli).to receive(:gets).and_return("\n")

        expect { cli.send(:handle_input) }.not_to raise_error
      end
    end

    context 'when input is nil' do
      it 'returns without error' do
        allow(cli).to receive(:gets).and_return(nil)

        expect { cli.send(:handle_input) }.not_to raise_error
      end
    end

    context 'when input is an unknown command' do
      it 'displays an error message' do
        allow(cli).to receive(:gets).and_return("unknown\n")

        expect(cli).to receive(:puts).with("Unknown command: unknown")
        expect(cli).to receive(:sleep).with(0.5)

        cli.send(:handle_input)
      end
    end

    context 'when Interrupt is raised' do
      it 'handles the interrupt gracefully' do
        allow(cli).to receive(:gets).and_raise(Interrupt)

        expect(cli).to receive(:puts).with("\n\nInterrupt!")

        cli.send(:handle_input)

        expect(cli.instance_variable_get(:@running)).to be false
      end
    end

    context 'with TODO commands' do
      %w[add complete edit delete].each do |command|
        context "when input is '#{command}'" do
          it 'accepts the command without error (TODO)' do
            allow(cli).to receive(:gets).and_return("#{command} test\n")

            expect { cli.send(:handle_input) }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#show_prompt (private)' do
    it 'displays the command prompt' do
      expect(cli).to receive(:puts).with("-" * 50)
      expect(cli).to receive(:puts).with("Commands: add <title> | complete <id> | edit <id> <title> | delete <id> | exit")
      expect(cli).to receive(:print).with("> ")

      cli.send(:show_prompt)
    end
  end

  describe '#clear_screen (private)' do
    it 'calls system("clear")' do
      expect(cli).to receive(:system).with("clear")

      cli.send(:clear_screen)
    end
  end

  describe '#display_tasks (private)' do
    it 'is a TODO method' do
      expect { cli.send(:display_tasks) }.not_to raise_error
    end
  end
end
