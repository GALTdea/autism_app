#!/usr/bin/env ruby
# Quick verification script for Phase 1 Assessment feature
# Run with: bin/rails runner script/verify_phase1.rb

puts "\n" + "="*60
puts "Phase 1 Verification - Assessment Feature"
puts "="*60

errors = []
warnings = []

# 1. Check tables exist
puts "\n1. Checking database tables..."
begin
  if Assessment.table_exists? && AssessmentDomain.table_exists?
    puts "   ✓ Tables exist"
  else
    errors << "Tables missing"
    puts "   ✗ Tables missing"
  end
rescue => e
  errors << "Error checking tables: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# 2. Check assessments exist
puts "\n2. Checking seed data..."
begin
  assessment_count = Assessment.count
  if assessment_count >= 1
    puts "   ✓ Found #{assessment_count} assessment(s)"
  else
    warnings << "No assessments found - run: bin/rails db:seed"
    puts "   ⚠ No assessments found"
  end

  default_assessment = Assessment.default.first
  if default_assessment
    puts "   ✓ Default assessment exists: #{default_assessment.name} v#{default_assessment.version}"
    puts "     Domains: #{default_assessment.domain_count}"
  else
    warnings << "No default assessment found"
    puts "   ⚠ No default assessment found"
  end
rescue => e
  errors << "Error checking assessments: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# 3. Check associations work
puts "\n3. Checking model associations..."
begin
  if default_assessment
    domain_count = default_assessment.profile_domains.count
    ad_count = default_assessment.assessment_domains.count

    if domain_count == ad_count && domain_count > 0
      puts "   ✓ Associations working (#{domain_count} domains)"
    else
      errors << "Association mismatch: #{domain_count} domains vs #{ad_count} assessment_domains"
      puts "   ✗ Association mismatch"
    end
  end
rescue => e
  errors << "Error checking associations: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# 4. Check OnboardingSession has assessment
puts "\n4. Checking OnboardingSession integration..."
begin
  sessions_with_assessment = OnboardingSession.where.not(assessment_id: nil).count
  total_sessions = OnboardingSession.count

  if total_sessions > 0
    if sessions_with_assessment == total_sessions
      puts "   ✓ All sessions have assessments (#{total_sessions} sessions)"
    else
      warnings << "#{total_sessions - sessions_with_assessment} sessions without assessment"
      puts "   ⚠ #{sessions_with_assessment}/#{total_sessions} sessions have assessments"
    end
  else
    puts "   ℹ No onboarding sessions yet"
  end
rescue => e
  errors << "Error checking sessions: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# 5. Test Assessment methods
puts "\n5. Testing Assessment methods..."
begin
  if default_assessment
    # Test domain_count
    count = default_assessment.domain_count
    if count.is_a?(Integer) && count >= 0
      puts "   ✓ domain_count works: #{count}"
    else
      errors << "domain_count returned invalid value"
      puts "   ✗ domain_count failed"
    end

    # Test ordered_domains
    ordered = default_assessment.ordered_domains.to_a
    if ordered.is_a?(Array)
      puts "   ✓ ordered_domains works: #{ordered.count} domains"
    else
      errors << "ordered_domains failed"
      puts "   ✗ ordered_domains failed"
    end
  end
rescue => e
  errors << "Error testing methods: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# 6. Check ProfileDomain associations
puts "\n6. Checking ProfileDomain associations..."
begin
  domain = ProfileDomain.first
  if domain
    assessment_count = domain.assessments.count
    ad_count = domain.assessment_domains.count

    if assessment_count == ad_count
      puts "   ✓ ProfileDomain associations working"
    else
      warnings << "ProfileDomain association mismatch"
      puts "   ⚠ Association count mismatch"
    end
  end
rescue => e
  errors << "Error checking ProfileDomain: #{e.message}"
  puts "   ✗ Error: #{e.message}"
end

# Summary
puts "\n" + "="*60
puts "Summary"
puts "="*60

if errors.empty? && warnings.empty?
  puts "✅ Phase 1 verification PASSED!"
  puts "\nAll checks passed. Phase 1 is ready to use."
  exit 0
elsif errors.empty?
  puts "⚠️  Phase 1 verification PASSED with warnings:"
  warnings.each { |w| puts "   - #{w}" }
  puts "\nPhase 1 is functional but may need attention."
  exit 0
else
  puts "❌ Phase 1 verification FAILED:"
  errors.each { |e| puts "   ✗ #{e}" }
  warnings.each { |w| puts "   ⚠ #{w}" }
  puts "\nPlease fix the errors above."
  exit 1
end
