class CreateSessionResources < ActiveRecord::Migration[7.1]
  def change
    create_table :session_resources do |t|
      t.string :title, null: false
      t.integer :resource_type, default: 0, null: false
      t.references :session, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :session_resources, :resource_type
  end
end
