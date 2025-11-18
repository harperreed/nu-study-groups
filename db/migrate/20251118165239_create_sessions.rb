class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :title, null: false
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :location
      t.string :meeting_link
      t.text :description
      t.integer :max_capacity
      t.text :prep_materials
      t.references :study_group, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sessions, :date
  end
end
