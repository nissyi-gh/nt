require 'date'

RSpec.describe NT::CLI do
  let(:cli) { described_class.new }
  let(:task_manager) { instance_double(NT::TaskManager) }

  before do
    allow(cli).to receive(:puts)
    allow(cli).to receive(:print)
    allow(cli).to receive(:sleep)
    cli.instance_variable_set(:@task_manager, task_manager)
  end

  describe '#edit_due_date (private)' do
    context 'with valid task and date' do
      it 'sets due date with YYYY-MM-DD format' do
        expect(task_manager).to receive(:edit_due_date)
          .with(1, Date.parse('2025-12-31'))
          .and_return(true)
        expect(cli).to receive(:puts).with("Due date set to 2025-12-31 for task 1")

        cli.send(:edit_due_date, 1, '2025-12-31')
      end

      it 'sets due date with "today" keyword' do
        expect(task_manager).to receive(:edit_due_date)
          .with(1, Date.today)
          .and_return(true)
        expect(cli).to receive(:puts).with("Due date set to #{Date.today} for task 1")

        cli.send(:edit_due_date, 1, 'today')
      end

      it 'sets due date with "tomorrow" keyword' do
        tomorrow = Date.today + 1
        expect(task_manager).to receive(:edit_due_date)
          .with(1, tomorrow)
          .and_return(true)
        expect(cli).to receive(:puts).with("Due date set to #{tomorrow} for task 1")

        cli.send(:edit_due_date, 1, 'tomorrow')
      end

      it 'clears due date with "none" keyword' do
        expect(task_manager).to receive(:edit_due_date)
          .with(1, nil)
          .and_return(true)
        expect(cli).to receive(:puts).with("Due date cleared for task 1")

        cli.send(:edit_due_date, 1, 'none')
      end

      it 'clears due date with "clear" keyword' do
        expect(task_manager).to receive(:edit_due_date)
          .with(1, nil)
          .and_return(true)
        expect(cli).to receive(:puts).with("Due date cleared for task 1")

        cli.send(:edit_due_date, 1, 'clear')
      end
    end

    context 'when task does not exist' do
      it 'shows error message' do
        expect(task_manager).to receive(:edit_due_date)
          .with(999, Date.today)
          .and_return(false)
        expect(cli).to receive(:puts).with("Task 999 not found.")

        cli.send(:edit_due_date, 999, 'today')
      end
    end

    context 'when date_str is invalid' do
      it 'shows error for invalid date format' do
        expect(cli).to receive(:puts).with("Error: Invalid date format. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
        expect(task_manager).not_to receive(:edit_due_date)

        cli.send(:edit_due_date, 1, 'invalid-date')
      end
    end

    context 'when date_str is empty' do
      it 'shows error message' do
        expect(cli).to receive(:puts)
          .with("Error: Date is required. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
        expect(task_manager).not_to receive(:edit_due_date)

        cli.send(:edit_due_date, 1, '')
      end
    end

    context 'when date_str is nil' do
      it 'shows error message' do
        expect(cli).to receive(:puts)
          .with("Error: Date is required. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
        expect(task_manager).not_to receive(:edit_due_date)

        cli.send(:edit_due_date, 1, nil)
      end
    end

    context 'when id is nil' do
      it 'returns without error' do
        expect(task_manager).not_to receive(:edit_due_date)
        expect { cli.send(:edit_due_date, nil, 'today') }.not_to raise_error
      end
    end
  end

  describe '#parse_date_string (private)' do
    it 'returns nil for "none"' do
      expect(cli.send(:parse_date_string, 'none')).to be_nil
    end

    it 'returns nil for "clear"' do
      expect(cli.send(:parse_date_string, 'clear')).to be_nil
    end

    it 'returns today\'s date for "today"' do
      expect(cli.send(:parse_date_string, 'today')).to eq(Date.today)
    end

    it 'returns tomorrow\'s date for "tomorrow"' do
      expect(cli.send(:parse_date_string, 'tomorrow')).to eq(Date.today + 1)
    end

    it 'parses YYYY-MM-DD format' do
      expect(cli.send(:parse_date_string, '2025-12-31')).to eq(Date.parse('2025-12-31'))
    end

    it 'parses YYYYMMDD format' do
      expect(cli.send(:parse_date_string, '20251231')).to eq(Date.new(2025, 12, 31))
    end

    it 'parses MMDD format for current year' do
      # Use a date in the future of the current year
      future_date = Date.new(Date.today.year, 12, 31)
      if future_date < Date.today
        future_date = Date.new(Date.today.year + 1, 12, 31)
      end
      expect(cli.send(:parse_date_string, '1231')).to eq(future_date)
    end

    it 'parses MMDD format for next year if date has passed' do
      # Use a date that has definitely passed this year
      past_month = 1
      past_day = 1
      past_date = Date.new(Date.today.year, past_month, past_day)

      if past_date < Date.today
        expected = Date.new(Date.today.year + 1, past_month, past_day)
      else
        expected = past_date
      end

      expect(cli.send(:parse_date_string, '0101')).to eq(expected)
    end

    it 'raises ArgumentError for invalid YYYYMMDD format' do
      expect { cli.send(:parse_date_string, '20251332') }  # Invalid month
        .to raise_error(ArgumentError, "Invalid date format. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
    end

    it 'raises ArgumentError for invalid MMDD format' do
      expect { cli.send(:parse_date_string, '1332') }  # Invalid month
        .to raise_error(ArgumentError, "Invalid date format. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
    end

    it 'raises ArgumentError for invalid date format' do
      expect { cli.send(:parse_date_string, 'invalid') }
        .to raise_error(ArgumentError, "Invalid date format. Use YYYY-MM-DD, YYYYMMDD, MMDD, 'today', 'tomorrow', or 'none'")
    end
  end

  describe '#handle_input with due command' do
    before do
      allow(cli).to receive(:gets).and_return("due 1 today\n")
    end

    it 'parses due command correctly' do
      expect(cli).to receive(:edit_due_date).with(1, "today")
      cli.send(:handle_input)
    end
  end
end
