class BackfillOnboardingSessionsWithDefaultAssessment < ActiveRecord::Migration[8.0]
  def up
    # Create default assessment with all existing profile domains
    connection.execute(<<-SQL.squish
      INSERT INTO assessments (name, version, description, active, is_default, created_at, updated_at)
      VALUES ('Full Assessment', '1.0', 'Complete assessment with all profile domains', 1, 1, datetime('now'), datetime('now'))
    SQL
    )

    # Get the ID of the assessment we just created
    default_assessment_id = connection.select_value(<<-SQL.squish
      SELECT id FROM assessments WHERE name = 'Full Assessment' AND version = '1.0' LIMIT 1
    SQL
    )

    # Bug 1 Fix: Validate that the assessment was created successfully
    raise "Failed to create default assessment" if default_assessment_id.nil? || default_assessment_id.to_i.zero?

    default_assessment_id = default_assessment_id.to_i

    # Add all profile domains to the assessment in order
    profile_domains = connection.select_all(<<-SQL.squish
      SELECT id FROM profile_domains ORDER BY label
    SQL
    )

    profile_domains.each_with_index do |domain, index|
      # Bug 2 Fix: Use quote to properly escape values
      assessment_id_quoted = connection.quote(default_assessment_id)
      domain_id_quoted = connection.quote(domain['id'])
      position_quoted = connection.quote(index)

      connection.execute(<<-SQL.squish
        INSERT INTO assessment_domains (assessment_id, profile_domain_id, position, created_at, updated_at)
        VALUES (#{assessment_id_quoted}, #{domain_id_quoted}, #{position_quoted}, datetime('now'), datetime('now'))
      SQL
      )
    end

    # Update all existing onboarding sessions to reference the default assessment
    assessment_id_quoted = connection.quote(default_assessment_id)
    connection.execute(<<-SQL.squish
      UPDATE onboarding_sessions SET assessment_id = #{assessment_id_quoted}
    SQL
    )
  end

  def down
    # Remove assessment references from onboarding sessions
    connection.execute("UPDATE onboarding_sessions SET assessment_id = NULL")

    # Bug 3 Fix: Delete assessment_domains first (or rely on cascade if foreign key has on_delete: :cascade)
    # Since we fixed the foreign key to cascade, we can delete the assessment directly
    connection.execute("DELETE FROM assessments WHERE name = 'Full Assessment' AND version = '1.0'")
  end
end
