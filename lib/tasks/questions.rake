namespace :questions do
  desc "Import questions from JSON file(s)"
  task :import, [:filename] => :environment do |t, args|
    if args[:filename].present?
      # Import single file
      file_path = Rails.root.join("db", "seeds", "questions", args[:filename])

      unless File.exist?(file_path)
        puts "❌ Error: File not found: #{file_path}"
        exit 1
      end

      puts "📥 Importing questions from: #{args[:filename]}"
      begin
        results = QuestionBulkImportService.import_from_file(file_path)
        print_results(results)
      rescue QuestionBulkImportService::Error => e
        puts "❌ Import failed: #{e.message}"
        exit 1
      end
    else
      # Import all JSON files in directory
      questions_dir = Rails.root.join("db", "seeds", "questions")

      unless Dir.exist?(questions_dir)
        puts "📁 Creating directory: #{questions_dir}"
        FileUtils.mkdir_p(questions_dir)
        puts "✅ Directory created. Add JSON files to import."
        exit 0
      end

      json_files = Dir.glob(questions_dir.join("*.json"))

      if json_files.empty?
        puts "ℹ️  No JSON files found in #{questions_dir}"
        puts "   Add JSON files to import, or use: rake questions:import[filename.json]"
        exit 0
      end

      puts "📥 Found #{json_files.count} JSON file(s) to import\n\n"

      json_files.each do |file_path|
        filename = File.basename(file_path)
        puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        puts "📄 Importing: #{filename}"
        puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        begin
          results = QuestionBulkImportService.import_from_file(file_path)
          print_results(results)
          puts "✅ Successfully imported: #{filename}\n\n"
        rescue QuestionBulkImportService::Error => e
          puts "❌ Failed to import #{filename}: #{e.message}\n\n"
        end
      end

      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "✅ Import process complete"
    end
  end

  desc "Create example JSON file template"
  task :create_template, [:filename] => :environment do |t, args|
    filename = args[:filename] || "example_questions.json"
    file_path = Rails.root.join("db", "seeds", "questions", filename)

    # Create directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(file_path))

    template = {
      domain: {
        key: "communication",
        label: "Communication Skills",
        description: "Verbal and non-verbal communication abilities"
      },
      questions: [
        {
          code: "COMM_1",
          text: "How does the child express basic needs?",
          response_type: "scale",
          position: 0,
          options: [
            { label: "Not at all", value: 0, position: 0 },
            { label: "Rarely", value: 1, position: 1 },
            { label: "Sometimes", value: 2, position: 2 },
            { label: "Often", value: 3, position: 3 },
            { label: "Always", value: 4, position: 4 }
          ]
        },
        {
          code: "COMM_2",
          text: "Describe the child's use of gestures to communicate.",
          response_type: "text",
          position: 1,
          options: []
        }
      ]
    }

    File.write(file_path, JSON.pretty_generate(template))
    puts "✅ Created template file: #{file_path}"
    puts "   Edit this file and run: rake questions:import[#{filename}]"
  end

  private

  def print_results(results)
    puts "\n📊 Import Results:"

    if results[:domains_created].any?
      puts "   ✅ Domains created: #{results[:domains_created].count}"
      results[:domains_created].each do |domain|
        puts "      • #{domain.label} (#{domain.key})"
      end
    end

    if results[:questions_imported].any?
      puts "   ✅ Questions imported: #{results[:questions_imported].count}"
    end

    if results[:questions_updated].any?
      puts "   🔄 Questions updated: #{results[:questions_updated].count}"
    end

    if results[:warnings].any?
      puts "   ⚠️  Warnings: #{results[:warnings].count}"
      results[:warnings].first(5).each do |warning|
        puts "      • #{warning[:message]}"
      end
      puts "      ..." if results[:warnings].count > 5
    end

    if results[:errors].any?
      puts "   ❌ Errors: #{results[:errors].count}"
      results[:errors].first(5).each do |error|
        puts "      • #{error[:error]}"
      end
      puts "      ..." if results[:errors].count > 5
    end
  end
end
