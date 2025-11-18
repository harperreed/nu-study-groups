class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :semester, null: false
      t.integer :year, null: false

      t.timestamps
    end

    add_index :courses, [:code, :semester, :year], unique: true
  end
end
