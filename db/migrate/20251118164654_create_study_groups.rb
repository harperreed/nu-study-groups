class CreateStudyGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :study_groups do |t|
      t.string :name, null: false
      t.text :description
      t.integer :group_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.references :course, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :study_groups, :group_type
    add_index :study_groups, :status
  end
end
