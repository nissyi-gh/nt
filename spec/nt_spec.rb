RSpec.describe NT do
  describe '.run' do
    let(:cli_instance) { instance_double(NT::CLI) }

    before do
      allow(NT::CLI).to receive(:new).and_return(cli_instance)
      allow(cli_instance).to receive(:run)
    end

    it 'creates a new CLI instance' do
      expect(NT::CLI).not_to receive(:new).and_return(cli_instance)

      described_class.run
    end

    it 'calls run on the CLI instance' do
      expect(cli_instance).to receive(:run)

      described_class.run
    end
  end
end
