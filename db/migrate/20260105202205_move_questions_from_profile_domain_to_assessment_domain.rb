class MoveQuestionsFromProfileDomainToAssessmentDomain < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Add assessment_domain_id column (nullable initially)
    # Note: add_reference automatically creates an index, so we don't need a separate add_index
    add_reference :questions, :assessment_domain, null: true, foreign_key: true

    # Step 2: Temporarily remove unique constraint on code to allow duplicates during migration
    remove_index :questions, :code

    # Step 3: Create a mapping to track original question -> new question copies
    # This will help us update answers later
    question_mapping = {} # { original_question_id => { assessment_id => new_question_id } }

    # Step 4: Migrate questions - copy each question to all relevant assessment_domains
    orphaned_question_ids = []

    Question.find_each do |original_question|
      # Read profile_domain_id directly from the database to avoid delegation issues
      # During migration, assessment_domain_id is nil, so delegation would fail
      profile_domain_id = original_question.read_attribute(:profile_domain_id)

      if profile_domain_id.nil?
        say "Warning: Question #{original_question.code} (#{original_question.id}) has no profile_domain_id - skipping", true
        orphaned_question_ids << original_question.id
        next
      end

      # Find all assessment_domains that reference this profile_domain
      assessment_domains = AssessmentDomain.where(profile_domain_id: profile_domain_id)

      if assessment_domains.empty?
        say "Warning: Question #{original_question.code} (#{original_question.id}) has no assessment_domains to migrate to - will be deleted", true
        orphaned_question_ids << original_question.id
        next
      end

      question_mapping[original_question.id] = {}

      # Copy question to each assessment_domain
      assessment_domains.each do |assessment_domain|
        # Create a copy of the question
        new_question = Question.create!(
          code: original_question.code, # Will update unique constraint later
          text: original_question.text,
          domain: original_question.domain,
          response_type: original_question.response_type,
          position: original_question.position,
          assessment_domain_id: assessment_domain.id,
          created_at: original_question.created_at,
          updated_at: original_question.updated_at
        )

        question_mapping[original_question.id][assessment_domain.assessment_id] = new_question.id

        # Copy question_options
        original_question.question_options.each do |original_option|
          QuestionOption.create!(
            question_id: new_question.id,
            label: original_option.label,
            value: original_option.value,
            position: original_option.position,
            created_at: original_option.created_at,
            updated_at: original_option.updated_at
          )
        end

        say "  Copied question #{original_question.code} to assessment #{assessment_domain.assessment.name} v#{assessment_domain.assessment.version}", true
      end
    end

    # Step 5: Update answers to point to the correct question copies
    Answer.find_each do |answer|
      original_question_id = answer.question_id
      onboarding_session = answer.onboarding_session

      # Get the assessment for this onboarding session
      assessment = onboarding_session.assessment

      if assessment.nil?
        say "Warning: Answer #{answer.id} has no assessment - cannot map to new question", true
        next
      end

      # Find the new question_id for this assessment
      if question_mapping[original_question_id] && question_mapping[original_question_id][assessment.id]
        new_question_id = question_mapping[original_question_id][assessment.id]

        # Update question_id
        answer.update_column(:question_id, new_question_id)

        # Update question_option_id if it exists (need to find the matching option in the new question)
        if answer.question_option_id.present?
          original_option = QuestionOption.find_by(id: answer.question_option_id)
          if original_option
            new_question = Question.find(new_question_id)
            # Find matching option by value (should be unique per question)
            new_option = new_question.question_options.find_by(value: original_option.value)
            if new_option
              answer.update_column(:question_option_id, new_option.id)
            end
          end
        end
      else
        say "Warning: Could not find new question for answer #{answer.id} (original question #{original_question_id}, assessment #{assessment.id})", true
      end
    end

    # Step 6: Delete original questions (they've been copied to assessment_domains)
    # Delete questions that still have profile_domain_id (originals) but no assessment_domain_id
    # Also delete orphaned questions (those with no assessment_domains)
    questions_to_delete = Question.where.not(profile_domain_id: nil).where(assessment_domain_id: nil)
    deleted_count = questions_to_delete.count
    questions_to_delete.destroy_all
    say "Deleted #{deleted_count} original questions", true

    if orphaned_question_ids.any?
      say "Deleted #{orphaned_question_ids.count} orphaned questions with no assessment_domains", true
    end

    # Step 7: Make assessment_domain_id required (all remaining questions should have it)
    change_column_null :questions, :assessment_domain_id, false

    # Step 8: Remove profile_domain_id and update indexes
    remove_index :questions, [:profile_domain_id, :position] if index_exists?(:questions, [:profile_domain_id, :position])
    remove_index :questions, :profile_domain_id if index_exists?(:questions, :profile_domain_id)
    remove_foreign_key :questions, :profile_domains if foreign_key_exists?(:questions, :profile_domains)
    # Remove the column (foreign key already removed above)
    remove_column :questions, :profile_domain_id

    # Step 9: Add new unique constraint on code scoped to assessment_domain_id
    add_index :questions, [:code, :assessment_domain_id], unique: true, name: 'index_questions_on_code_and_assessment_domain_id'
    add_index :questions, [:assessment_domain_id, :position], name: 'index_questions_on_assessment_domain_id_and_position'
  end

  def down
    # Rollback is complex - would need to merge questions back
    # For now, this is a one-way migration
    raise ActiveRecord::IrreversibleMigration, "This migration cannot be reversed automatically"
  end
end
