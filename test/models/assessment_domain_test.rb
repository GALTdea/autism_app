require "test_helper"

class AssessmentDomainTest < ActiveSupport::TestCase
  def setup
    @assessment = Assessment.create!(
      name: "Test Assessment",
      version: "1.0",
      active: true
    )
    @domain = ProfileDomain.first || ProfileDomain.create!(
      key: "test_domain",
      label: "Test Domain"
    )
    @assessment_domain = AssessmentDomain.create!(
      assessment: @assessment,
      profile_domain: @domain,
      position: 0
    )
  end

  test "should be valid" do
    assert @assessment_domain.valid?
  end

  test "should require assessment" do
    @assessment_domain.assessment = nil
    assert_not @assessment_domain.valid?
  end

  test "should require profile_domain" do
    @assessment_domain.profile_domain = nil
    assert_not @assessment_domain.valid?
  end

  test "should require position" do
    @assessment_domain.position = nil
    assert_not @assessment_domain.valid?
  end

  test "should enforce unique profile_domain per assessment" do
    duplicate = AssessmentDomain.new(
      assessment: @assessment,
      profile_domain: @domain,
      position: 1
    )
    assert_not duplicate.valid?
  end

  test "should allow same profile_domain in different assessments" do
    other_assessment = Assessment.create!(
      name: "Other Assessment",
      version: "1.0",
      active: true
    )

    other_assessment_domain = AssessmentDomain.new(
      assessment: other_assessment,
      profile_domain: @domain,
      position: 0
    )

    assert other_assessment_domain.valid?
  end

  test "ordered scope should return by position" do
    domain2 = ProfileDomain.second || ProfileDomain.create!(
      key: "test_domain2",
      label: "Test Domain 2"
    )

    ad2 = AssessmentDomain.create!(
      assessment: @assessment,
      profile_domain: domain2,
      position: 1
    )

    ordered = AssessmentDomain.ordered.to_a
    assert_equal @assessment_domain.id, ordered.first.id
    assert_equal ad2.id, ordered.second.id
  end

  test "should belong to assessment" do
    assert_equal @assessment.id, @assessment_domain.assessment.id
  end

  test "should belong to profile_domain" do
    assert_equal @domain.id, @assessment_domain.profile_domain.id
  end
end


