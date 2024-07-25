class CreateOperations < ActiveRecord::Migration[7.1]
  def change
    create_table :operations do |t|
      t.integer :status, default: 0
      t.integer :kill_status, default: 0
      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :pinged_at

      t.timestamps
    end
  end
end
