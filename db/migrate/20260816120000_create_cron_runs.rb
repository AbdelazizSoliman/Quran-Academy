class CreateCronRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :cron_runs do |t|
      t.string :task_name, null: false
      t.date :run_on, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_index :cron_runs, %i[task_name run_on], unique: true
  end
end
