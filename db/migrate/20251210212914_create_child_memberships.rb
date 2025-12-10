class CreateChildMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :child_memberships do |t|
      t.references :user, users: true, null: false, foreign_key: true
      t.references :child_profile, child_profiles: true, null: false, foreign_key: true
      t.string :role
      t.boolean :is_primary

      t.timestamps
    end
  end
end
