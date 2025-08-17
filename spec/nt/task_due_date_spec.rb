require 'date'

RSpec.describe NT::Task do
  let(:today) { Date.today }
  let(:tomorrow) { today + 1 }
  let(:yesterday) { today - 1 }
  let(:next_week) { today + 7 }

  describe 'due date initialization' do
    it 'accepts nil due_date' do
      task = described_class.new(id: 1, title: "No due date")
      expect(task.due_date).to be_nil
    end

    it 'accepts Date object' do
      task = described_class.new(id: 1, title: "Task", due_date: tomorrow)
      expect(task.due_date).to eq(tomorrow)
    end

    it 'accepts date string' do
      task = described_class.new(id: 1, title: "Task", due_date: "2024-12-31")
      expect(task.due_date).to eq(Date.parse("2024-12-31"))
    end

    it 'accepts Time object' do
      time = Time.now
      task = described_class.new(id: 1, title: "Task", due_date: time)
      expect(task.due_date).to eq(time.to_date)
    end

    it 'raises error for invalid date string' do
      expect {
        described_class.new(id: 1, title: "Task", due_date: "invalid")
      }.to raise_error(ArgumentError, /Invalid date string/)
    end
  end

  describe '#update_due_date' do
    let(:task) { described_class.new(id: 1, title: "Task") }

    it 'updates the due date' do
      task.update_due_date(tomorrow)
      expect(task.due_date).to eq(tomorrow)
    end

    it 'can set due date to nil' do
      task.update_due_date(tomorrow)
      task.update_due_date(nil)
      expect(task.due_date).to be_nil
    end
  end

  describe '#overdue?' do
    context 'when due date is in the past' do
      let(:task) { described_class.new(id: 1, title: "Task", due_date: yesterday) }

      it 'returns true for incomplete task' do
        expect(task.overdue?).to be true
      end

      it 'returns false for completed task' do
        task.complete!
        expect(task.overdue?).to be false
      end
    end

    context 'when due date is today' do
      let(:task) { described_class.new(id: 1, title: "Task", due_date: today) }

      it 'returns false' do
        expect(task.overdue?).to be false
      end
    end

    context 'when due date is in the future' do
      let(:task) { described_class.new(id: 1, title: "Task", due_date: tomorrow) }

      it 'returns false' do
        expect(task.overdue?).to be false
      end
    end

    context 'when no due date' do
      let(:task) { described_class.new(id: 1, title: "Task") }

      it 'returns false' do
        expect(task.overdue?).to be false
      end
    end
  end

  describe '#due_today?' do
    context 'when due date is today' do
      let(:task) { described_class.new(id: 1, title: "Task", due_date: today) }

      it 'returns true' do
        expect(task.due_today?).to be true
      end
    end

    context 'when due date is not today' do
      let(:task) { described_class.new(id: 1, title: "Task", due_date: tomorrow) }

      it 'returns false' do
        expect(task.due_today?).to be false
      end
    end

    context 'when no due date' do
      let(:task) { described_class.new(id: 1, title: "Task") }

      it 'returns false' do
        expect(task.due_today?).to be false
      end
    end
  end

  describe '#due_soon?' do
    context 'with default 3 days window' do
      it 'returns true for task due today' do
        task = described_class.new(id: 1, title: "Task", due_date: today)
        expect(task.due_soon?).to be true
      end

      it 'returns true for task due in 3 days' do
        task = described_class.new(id: 1, title: "Task", due_date: today + 3)
        expect(task.due_soon?).to be true
      end

      it 'returns false for task due in 4 days' do
        task = described_class.new(id: 1, title: "Task", due_date: today + 4)
        expect(task.due_soon?).to be false
      end

      it 'returns false for overdue task' do
        task = described_class.new(id: 1, title: "Task", due_date: yesterday)
        expect(task.due_soon?).to be false
      end

      it 'returns false for completed task' do
        task = described_class.new(id: 1, title: "Task", due_date: tomorrow)
        task.complete!
        expect(task.due_soon?).to be false
      end
    end

    context 'with custom days window' do
      it 'returns true for task within custom window' do
        task = described_class.new(id: 1, title: "Task", due_date: today + 5)
        expect(task.due_soon?(7)).to be true
      end
    end

    context 'when no due date' do
      let(:task) { described_class.new(id: 1, title: "Task") }

      it 'returns false' do
        expect(task.due_soon?).to be false
      end
    end
  end

  describe '#days_until_due' do
    it 'returns positive number for future due date' do
      task = described_class.new(id: 1, title: "Task", due_date: today + 5)
      expect(task.days_until_due).to eq(5)
    end

    it 'returns 0 for today' do
      task = described_class.new(id: 1, title: "Task", due_date: today)
      expect(task.days_until_due).to eq(0)
    end

    it 'returns negative number for past due date' do
      task = described_class.new(id: 1, title: "Task", due_date: today - 3)
      expect(task.days_until_due).to eq(-3)
    end

    it 'returns nil when no due date' do
      task = described_class.new(id: 1, title: "Task")
      expect(task.days_until_due).to be_nil
    end
  end

  describe '#to_s with due dates' do
    it 'shows no due date info when due_date is nil' do
      task = described_class.new(id: 1, title: "Task")
      expect(task.to_s).to eq("[ ] 1: Task")
    end

    it 'shows normal due date for future dates' do
      task = described_class.new(id: 1, title: "Task", due_date: next_week)
      expect(task.to_s).to include("(期限: #{next_week})")
    end

    it 'shows warning for overdue tasks' do
      task = described_class.new(id: 1, title: "Task", due_date: yesterday)
      expect(task.to_s).to include("⚠️ (期限切れ: #{yesterday})")
    end

    it 'shows today indicator for tasks due today' do
      task = described_class.new(id: 1, title: "Task", due_date: today)
      expect(task.to_s).to include("📅 (本日期限)")
    end

    it 'shows alarm for tasks due soon' do
      task = described_class.new(id: 1, title: "Task", due_date: tomorrow)
      expect(task.to_s).to include("⏰ (期限: #{tomorrow})")
    end

    it 'shows normal due date for completed tasks' do
      task = described_class.new(id: 1, title: "Task", due_date: yesterday)
      task.complete!
      expect(task.to_s).to include("[✓]")
      expect(task.to_s).to include("(期限: #{yesterday})")
      expect(task.to_s).not_to include("⚠️")
    end
  end
end
