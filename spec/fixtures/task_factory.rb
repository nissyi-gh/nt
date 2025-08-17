module NT
  module Fixtures
    class TaskFactory
      def self.create_simple_task(id: 1, title: "Simple Task", completed: false)
        task = Task.new(id: id, title: title)
        task.complete! if completed
        task
      end

      def self.create_task_tree
        # 親タスク
        parent = Task.new(id: 1, title: "親タスク")

        # 子タスク
        child1 = Task.new(id: 2, title: "子タスク1", parent: parent)
        child2 = Task.new(id: 3, title: "子タスク2", parent: parent)

        # 孫タスク
        grandchild1 = Task.new(id: 4, title: "孫タスク1-1", parent: child1)
        grandchild2 = Task.new(id: 5, title: "孫タスク1-2", parent: child1)
        grandchild3 = Task.new(id: 6, title: "孫タスク2-1", parent: child2)

        {
          parent: parent,
          children: [child1, child2],
          grandchildren: [grandchild1, grandchild2, grandchild3]
        }
      end

      def self.create_project_tasks
        tasks = []

        # プロジェクトタスク
        project = Task.new(id: 1, title: "プロジェクトX")
        tasks << project

        # フェーズ1
        phase1 = Task.new(id: 2, title: "フェーズ1: 企画", parent: project)
        phase1.complete!
        tasks << phase1

        requirement = Task.new(id: 3, title: "要件定義", parent: phase1)
        requirement.complete!
        tasks << requirement

        design_doc = Task.new(id: 4, title: "設計書作成", parent: phase1)
        design_doc.complete!
        tasks << design_doc

        # フェーズ2
        phase2 = Task.new(id: 5, title: "フェーズ2: 開発", parent: project)
        tasks << phase2

        implement = Task.new(id: 6, title: "実装", parent: phase2)
        tasks << implement

        frontend_impl = Task.new(id: 7, title: "フロントエンド実装", parent: implement)
        tasks << frontend_impl

        backend_impl = Task.new(id: 8, title: "バックエンド実装", parent: implement)
        backend_impl.complete!
        tasks << backend_impl

        testing = Task.new(id: 9, title: "テスト", parent: phase2)
        tasks << testing

        # フェーズ3
        phase3 = Task.new(id: 10, title: "フェーズ3: リリース", parent: project)
        tasks << phase3

        deploy = Task.new(id: 11, title: "デプロイ", parent: phase3)
        tasks << deploy

        monitor = Task.new(id: 12, title: "監視設定", parent: phase3)
        tasks << monitor

        tasks
      end
    end
  end
end
