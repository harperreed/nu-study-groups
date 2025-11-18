class CreateAttendanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_records do |t|
      t.references :session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
