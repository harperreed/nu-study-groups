class CreateAttendanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.boolean :attended, default: false, null: false
      t.text :notes
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :attendance_records, [:user_id, :session_id], unique: true
  end
end
