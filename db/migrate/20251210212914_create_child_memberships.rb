class CreateChildMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :child_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :child_profile, null: false, foreign_key: true
      t.string :role, null: false
      t.boolean :is_primary, default: false, null: false

      t.timestamps
    end

    add_index :child_memberships, [:user_id, :child_profile_id], unique: true
    add_index :child_memberships, :role
    add_index :child_memberships, :is_primary
    add_index :child_memberships, [:child_profile_id, :is_primary], where: 'is_primary = true', unique: true
  end
end
