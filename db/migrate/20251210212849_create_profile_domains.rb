class CreateProfileDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_domains do |t|
      t.string :key
      t.string :label
      t.text :description

      t.timestamps
    end
  end
end
