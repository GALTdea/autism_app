class AssessmentDomainService
  class Error < StandardError; end
  class InvalidDomainError < Error; end
  class UpdateError < Error; end

  def self.update_domains(assessment, domain_ids)
    new(assessment).update_domains(domain_ids)
  end

  def self.reorder_domains(assessment, domain_positions)
    new(assessment).reorder_domains(domain_positions)
  end

  def initialize(assessment)
    @assessment = assessment
    raise Error, "Assessment is required" if @assessment.nil?
  end

  def update_domains(domain_ids)
    domain_ids = Array(domain_ids).map(&:to_s).reject(&:blank?)

    ActiveRecord::Base.transaction do
      # Get current domain IDs
      current_domain_ids = @assessment.assessment_domains.pluck(:profile_domain_id).map(&:to_s)

      # Find domains to remove (in current but not in new list)
      domains_to_remove = current_domain_ids - domain_ids
      domains_to_remove.each do |domain_id|
        profile_domain = ProfileDomain.find_by(id: domain_id)
        next unless profile_domain
        @assessment.remove_domain(profile_domain)
      end

      # Find domains to add (in new list but not in current)
      domains_to_add = domain_ids - current_domain_ids
      domains_to_add.each do |domain_id|
        profile_domain = ProfileDomain.find_by(id: domain_id)
        raise InvalidDomainError, "Profile domain with ID #{domain_id} not found" unless profile_domain
        @assessment.add_domain(profile_domain)
      end

      # Verify the update was successful
      updated_domain_ids = @assessment.assessment_domains.pluck(:profile_domain_id).map(&:to_s).sort
      expected_domain_ids = domain_ids.sort

      unless updated_domain_ids == expected_domain_ids
        raise UpdateError, "Failed to update domains. Expected #{expected_domain_ids}, got #{updated_domain_ids}"
      end

      @assessment
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Validation failed: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error: #{e.message}"
    end
  end

  def reorder_domains(domain_positions)
    # domain_positions should be a hash: { domain_id => position }
    domain_positions = domain_positions.stringify_keys

    ActiveRecord::Base.transaction do
      domain_positions.each do |domain_id, position|
        assessment_domain = @assessment.assessment_domains.find_by(profile_domain_id: domain_id)
        next unless assessment_domain

        new_position = position.to_i
        assessment_domain.update!(position: new_position)
      end

      # Renormalize positions to ensure they're sequential starting from 0
      normalize_positions

      @assessment
    rescue ActiveRecord::RecordInvalid => e
      raise UpdateError, "Failed to reorder domains: #{e.message}"
    rescue StandardError => e
      raise UpdateError, "Unexpected error during reordering: #{e.message}"
    end
  end

  private

  def normalize_positions
    # Ensure positions are sequential starting from 0
    @assessment.assessment_domains.ordered.each_with_index do |assessment_domain, index|
      assessment_domain.update_column(:position, index)
    end
  end
end

