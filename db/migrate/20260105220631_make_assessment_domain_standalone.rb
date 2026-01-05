class MakeAssessmentDomainStandalone < ActiveRecord::Migration[8.0]
  def up
    # Step 1.1: Remove old uniqueness constraint (we'll recreate it as partial later)
    remove_index :assessment_domains, name: "index_assessment_domains_on_assessment_and_profile_domain" if index_exists?(:assessment_domains, [:assessment_id, :profile_domain_id], name: "index_assessment_domains_on_assessment_and_profile_domain")

    # Step 1.2: Add new columns before making old ones nullable (for backfilling)
    add_column :assessment_domains, :name, :string
    add_column :assessment_domains, :version, :string
    add_column :assessment_domains, :description, :text

    # Step 1.3: Backfill existing data with default names
    # Generate names based on assessment name + profile domain label
    say "Backfilling existing assessment_domains with default names...", true

    execute(<<-SQL.squish
      UPDATE assessment_domains
      SET name = (
        SELECT a.name || ' - ' || pd.label
        FROM assessments a
        JOIN profile_domains pd ON pd.id = assessment_domains.profile_domain_id
        WHERE a.id = assessment_domains.assessment_id
      )
      WHERE name IS NULL
    SQL
    )

    # Step 1.4: Make assessment_id nullable
    change_column_null :assessment_domains, :assessment_id, true

    # Step 1.5: Make profile_domain_id nullable
    change_column_null :assessment_domains, :profile_domain_id, true

    # Step 1.6: Make position nullable (only required when in an assessment)
    change_column_null :assessment_domains, :position, true

    # Step 1.7: Remove foreign key constraint on assessment_id (to allow nulls)
    # SQLite doesn't support removing foreign keys directly, but changing to null should work
    # The foreign key will still exist but won't enforce when null

    # Step 1.8: Add new partial uniqueness constraint (only for domains in assessments)
    # SQLite supports partial indexes - use raw SQL for compatibility
    execute(<<-SQL.squish
      CREATE UNIQUE INDEX index_assessment_domains_on_assessment_and_profile_domain_unique
      ON assessment_domains(assessment_id, profile_domain_id)
      WHERE assessment_id IS NOT NULL
    SQL
    )

    # Step 1.9: Add index on name for standalone domains (for faster lookups)
    execute(<<-SQL.squish
      CREATE INDEX index_assessment_domains_on_name_standalone
      ON assessment_domains(name)
      WHERE assessment_id IS NULL
    SQL
    )

    # Step 1.10: Add unique index on name + version for standalone domains (to prevent duplicates)
    execute(<<-SQL.squish
      CREATE UNIQUE INDEX index_assessment_domains_on_name_and_version_unique
      ON assessment_domains(name, version)
      WHERE assessment_id IS NULL AND name IS NOT NULL
    SQL
    )

    say "Migration complete. Existing assessment_domains have been backfilled with default names.", true
  end

  def down
    # Remove new indexes (using raw SQL since they're partial indexes)
    execute("DROP INDEX IF EXISTS index_assessment_domains_on_name_and_version_unique")
    execute("DROP INDEX IF EXISTS index_assessment_domains_on_name_standalone")
    execute("DROP INDEX IF EXISTS index_assessment_domains_on_assessment_and_profile_domain_unique")

    # Make columns non-nullable again (only if all records have values)
    # Note: This will fail if there are any null values - migration will need manual intervention
    change_column_null :assessment_domains, :position, false
    change_column_null :assessment_domains, :profile_domain_id, false
    change_column_null :assessment_domains, :assessment_id, false

    # Remove new columns
    remove_column :assessment_domains, :description
    remove_column :assessment_domains, :version
    remove_column :assessment_domains, :name

    # Restore original uniqueness constraint
    add_index :assessment_domains, [:assessment_id, :profile_domain_id],
              unique: true,
              name: "index_assessment_domains_on_assessment_and_profile_domain"
  end
end
