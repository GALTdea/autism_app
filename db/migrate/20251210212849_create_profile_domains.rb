class CreateProfileDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_domains do |t|
      t.string :key, null: false
      t.string :label, null: false
      t.text :description

      t.timestamps
    end

    add_index :profile_domains, :key, unique: true
  end
end
