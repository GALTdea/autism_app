class CreateAssessmentDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_domains do |t|
      t.timestamps
    end
  end
end
