class RemoveUniqueIndexFromStudyGroupMemberships < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique index that prevents rejoining after rejection
    remove_index :study_group_memberships, [:user_id, :study_group_id]

    # Add a partial unique index that only applies to non-rejected memberships
    # This allows users to rejoin a group after being rejected
    add_index :study_group_memberships,
              [:user_id, :study_group_id],
              unique: true,
              where: "status != 2",
              name: 'index_memberships_on_user_and_group_excluding_rejected'
  end
end
