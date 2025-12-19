require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  def setup
    @assessment = Assessment.create!(
      name: "Test Assessment",
      version: "1.0",
      description: "Test",
      active: true,
      is_default: false
    )
    @domain1 = profile_domains(:one) || ProfileDomain.first
    @domain2 = ProfileDomain.second
  end

  test "should be valid" do
    assert @assessment.valid?
  end

  test "should require name" do
    @assessment.name = nil
    assert_not @assessment.valid?
  end

  test "should require version" do
    @assessment.version = nil
    assert_not @assessment.valid?
  end

  test "should enforce unique name and version combination" do
    duplicate = Assessment.new(
      name: @assessment.name,
      version: @assessment.version
    )
    assert_not duplicate.valid?
  end

  test "should have many assessment_domains" do
    @assessment.add_domain(@domain1)
    assert_equal 1, @assessment.assessment_domains.count
  end

  test "should have many profile_domains through assessment_domains" do
    @assessment.add_domain(@domain1)
    assert_equal 1, @assessment.profile_domains.count
    assert_includes @assessment.profile_domains, @domain1
  end

  test "add_domain should set position automatically" do
    @assessment.add_domain(@domain1)
    @assessment.add_domain(@domain2)

    assert_equal 0, @assessment.assessment_domains.find_by(profile_domain: @domain1).position
    assert_equal 1, @assessment.assessment_domains.find_by(profile_domain: @domain2).position
  end

  test "add_domain should accept custom position" do
    @assessment.add_domain(@domain1, position: 5)
    assert_equal 5, @assessment.assessment_domains.find_by(profile_domain: @domain1).position
  end

  test "add_domain should not duplicate domains" do
    @assessment.add_domain(@domain1)
    @assessment.add_domain(@domain1)

    assert_equal 1, @assessment.assessment_domains.where(profile_domain: @domain1).count
  end

  test "remove_domain should remove domain from assessment" do
    @assessment.add_domain(@domain1)
    @assessment.remove_domain(@domain1)

    assert_equal 0, @assessment.profile_domains.count
  end

  test "domain_count should return correct count" do
    @assessment.add_domain(@domain1)
    @assessment.add_domain(@domain2)

    assert_equal 2, @assessment.domain_count
  end

  test "ordered_domains should return domains in position order" do
    @assessment.add_domain(@domain2, position: 1)
    @assessment.add_domain(@domain1, position: 0)

    ordered = @assessment.ordered_domains.to_a
    assert_equal @domain1.id, ordered.first.id
    assert_equal @domain2.id, ordered.second.id
  end

  test "activate! should set as default and deactivate others" do
    other = Assessment.create!(
      name: "Other",
      version: "1.0",
      is_default: true,
      active: true
    )

    @assessment.activate!

    assert @assessment.reload.is_default?
    assert_not other.reload.is_default?
  end

  test "deactivate! should remove default flag" do
    @assessment.update(is_default: true)
    @assessment.deactivate!

    assert_not @assessment.reload.is_default?
    assert_not @assessment.active?
  end

  test "default scope should return default assessment" do
    @assessment.update(is_default: true)
    assert_includes Assessment.default, @assessment
  end

  test "active scope should return active assessments" do
    @assessment.update(active: true)
    assert_includes Assessment.active, @assessment
  end
end


