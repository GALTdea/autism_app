class AssessmentCloningService
  class Error < StandardError; end
  class CloningError < Error; end

  def self.clone(assessment, new_name: nil, new_version: nil)
    new(assessment).clone(new_name: new_name, new_version: new_version)
  end

  def initialize(assessment)
    @assessment = assessment
    raise Error, "Assessment is required" if @assessment.nil?
  end

  def clone(new_name: nil, new_version: nil)
    ActiveRecord::Base.transaction do
      # Generate new name and version if not provided
      new_name ||= generate_clone_name
      new_version ||= generate_clone_version

      # Create new assessment with basic attributes
      cloned_assessment = Assessment.create!(
        name: new_name,
        version: new_version,
        description: @assessment.description,
        active: false, # Cloned assessments start as inactive
        is_default: false, # Cloned assessments are never default
        scoring_config: @assessment.scoring_config.deep_dup
      )

      # Clone assessment domains with their positions
      @assessment.assessment_domains.ordered.each do |assessment_domain|
        cloned_assessment.assessment_domains.create!(
          profile_domain_id: assessment_domain.profile_domain_id,
          position: assessment_domain.position
        )
      end

      cloned_assessment
    rescue ActiveRecord::RecordInvalid => e
      raise CloningError, "Failed to clone assessment: #{e.message}"
    rescue StandardError => e
      raise CloningError, "Unexpected error during cloning: #{e.message}"
    end
  end

  private

  def generate_clone_name
    base_name = @assessment.name
    # Remove any existing "(Copy)" suffix
    base_name = base_name.gsub(/\s*\(Copy\)\s*$/, "").strip

    # Try adding "(Copy)" suffix
    new_name = "#{base_name} (Copy)"

    # If that already exists, add a number
    if Assessment.exists?(name: new_name, version: @assessment.version)
      counter = 2
      loop do
        new_name = "#{base_name} (Copy #{counter})"
        break unless Assessment.exists?(name: new_name, version: @assessment.version)
        counter += 1
        raise CloningError, "Too many clones with same name" if counter > 100
      end
    end

    new_name
  end

  def generate_clone_version
    # Try incrementing the last digit of the version
    version = @assessment.version
    version_parts = version.split(".")

    if version_parts.last.match?(/^\d+$/)
      # Numeric last part - increment it
      last_part = version_parts.last.to_i + 1
      version_parts[-1] = last_part.to_s
      new_version = version_parts.join(".")
    else
      # Non-numeric last part - append ".1"
      new_version = "#{version}.1"
    end

    # Check if this version already exists for the same name
    # (We'll use the clone name, but check against original for safety)
    base_name = @assessment.name.gsub(/\s*\(Copy.*\)\s*$/, "").strip
    if Assessment.exists?(name: base_name, version: new_version)
      # Append additional suffix
      new_version = "#{new_version}.1"
    end

    new_version
  end
end

