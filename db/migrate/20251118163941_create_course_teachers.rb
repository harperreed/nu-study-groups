class CreateCourseTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :course_teachers do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :course_teachers, [:course_id, :user_id], unique: true
  end
end
