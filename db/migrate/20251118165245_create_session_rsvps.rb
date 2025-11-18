class CreateSessionRsvps < ActiveRecord::Migration[7.1]
  def change
    create_table :session_rsvps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :rsvp_at, null: false

      t.timestamps
    end

    add_index :session_rsvps, [:user_id, :session_id], unique: true
    add_index :session_rsvps, :status
  end
end
