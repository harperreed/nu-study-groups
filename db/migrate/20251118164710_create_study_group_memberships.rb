class CreateStudyGroupMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :study_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_group, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :requested_at, null: false
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :study_group_memberships, [:user_id, :study_group_id], unique: true
    add_index :study_group_memberships, :status
  end
end
