# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_16_213200) do
  create_table "activity_logs", force: :cascade do |t|
    t.integer "child_profile_id", null: false
    t.integer "activity_template_id", null: false
    t.datetime "occurred_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "completed", default: false, null: false
    t.integer "enjoyment", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_template_id", "occurred_at"], name: "index_activity_logs_on_activity_template_id_and_occurred_at"
    t.index ["activity_template_id"], name: "index_activity_logs_on_activity_template_id"
    t.index ["child_profile_id", "activity_template_id", "occurred_at"], name: "idx_on_child_profile_id_activity_template_id_occurr_921a8a4096"
    t.index ["child_profile_id", "occurred_at"], name: "index_activity_logs_on_child_profile_id_and_occurred_at"
    t.index ["child_profile_id"], name: "index_activity_logs_on_child_profile_id"
    t.index ["completed"], name: "index_activity_logs_on_completed"
    t.index ["enjoyment"], name: "index_activity_logs_on_enjoyment"
  end

  create_table "activity_templates", force: :cascade do |t|
    t.integer "primary_target_id", null: false
    t.string "title", null: false
    t.integer "duration_minutes", null: false
    t.text "materials", null: false
    t.text "parent_script", null: false
    t.text "variation", null: false
    t.json "secondary_target_ids", default: []
    t.json "target_tags", default: []
    t.json "age_bands", default: [], null: false
    t.string "language_level_required"
    t.string "motor_demands"
    t.integer "difficulty_level", null: false
    t.string "energy_level"
    t.json "contexts", default: []
    t.string "materials_category"
    t.json "scripts_by_level", default: {}
    t.json "sensory_fit", default: {}
    t.json "noise_level", default: {}
    t.json "movement_level", default: {}
    t.json "variations", default: []
    t.json "prerequisites", default: {}
    t.json "sensory_profile_tags", default: []
    t.json "supports_concerns", default: []
    t.boolean "active", default: true, null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_activity_templates_on_active"
    t.index ["age_bands"], name: "index_activity_templates_on_age_bands"
    t.index ["contexts"], name: "index_activity_templates_on_contexts"
    t.index ["difficulty_level"], name: "index_activity_templates_on_difficulty_level"
    t.index ["duration_minutes"], name: "index_activity_templates_on_duration_minutes"
    t.index ["energy_level"], name: "index_activity_templates_on_energy_level"
    t.index ["language_level_required"], name: "index_activity_templates_on_language_level_required"
    t.index ["materials_category"], name: "index_activity_templates_on_materials_category"
    t.index ["motor_demands"], name: "index_activity_templates_on_motor_demands"
    t.index ["primary_target_id"], name: "index_activity_templates_on_primary_target_id"
    t.index ["secondary_target_ids"], name: "index_activity_templates_on_secondary_target_ids"
    t.index ["sensory_profile_tags"], name: "index_activity_templates_on_sensory_profile_tags"
    t.index ["supports_concerns"], name: "index_activity_templates_on_supports_concerns"
    t.index ["target_tags"], name: "index_activity_templates_on_target_tags"
  end

  create_table "ai_documents", force: :cascade do |t|
    t.string "document_type", null: false
    t.integer "child_profile_id", null: false
    t.integer "onboarding_session_id"
    t.integer "created_by_id", null: false
    t.text "content_markdown", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_profile_id", "document_type", "created_at"], name: "idx_on_child_profile_id_document_type_created_at_0dcd06a998"
    t.index ["child_profile_id"], name: "index_ai_documents_on_child_profile_id"
    t.index ["created_by_id"], name: "index_ai_documents_on_created_by_id"
    t.index ["document_type"], name: "index_ai_documents_on_document_type"
    t.index ["onboarding_session_id"], name: "index_ai_documents_on_onboarding_session_id"
  end

  create_table "answers", force: :cascade do |t|
    t.integer "onboarding_session_id", null: false
    t.integer "question_id", null: false
    t.integer "question_option_id"
    t.integer "numeric_value"
    t.text "free_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["numeric_value"], name: "index_answers_on_numeric_value"
    t.index ["onboarding_session_id", "question_id"], name: "index_answers_on_onboarding_session_id_and_question_id", unique: true
    t.index ["onboarding_session_id"], name: "index_answers_on_onboarding_session_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["question_option_id"], name: "index_answers_on_question_option_id"
  end

  create_table "assessment_domains", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.integer "profile_domain_id", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "position"], name: "index_assessment_domains_on_assessment_id_and_position"
    t.index ["assessment_id", "profile_domain_id"], name: "index_assessment_domains_on_assessment_and_profile_domain", unique: true
    t.index ["assessment_id"], name: "index_assessment_domains_on_assessment_id"
    t.index ["profile_domain_id"], name: "index_assessment_domains_on_profile_domain_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.string "name", null: false
    t.string "version", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "scoring_config", default: {}
    t.index ["active"], name: "index_assessments_on_active"
    t.index ["is_default"], name: "index_assessments_on_is_default"
    t.index ["name", "version"], name: "index_assessments_on_name_and_version", unique: true
    t.index ["scoring_config"], name: "index_assessments_on_scoring_config"
  end

  create_table "child_domain_profiles", force: :cascade do |t|
    t.integer "child_profile_id", null: false
    t.integer "profile_domain_id", null: false
    t.integer "level_estimate"
    t.text "strengths_summary"
    t.text "needs_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "expressive_level"
    t.string "receptive_level"
    t.json "supports", default: []
    t.integer "seeking_level"
    t.integer "avoiding_level"
    t.json "sensitivity_tags", default: []
    t.index ["child_profile_id", "profile_domain_id"], name: "idx_on_child_profile_id_profile_domain_id_dc88cab075", unique: true
    t.index ["child_profile_id"], name: "index_child_domain_profiles_on_child_profile_id"
    t.index ["expressive_level"], name: "index_child_domain_profiles_on_expressive_level"
    t.index ["profile_domain_id"], name: "index_child_domain_profiles_on_profile_domain_id"
    t.index ["receptive_level"], name: "index_child_domain_profiles_on_receptive_level"
    t.index ["sensitivity_tags"], name: "index_child_domain_profiles_on_sensitivity_tags"
  end

  create_table "child_goals", force: :cascade do |t|
    t.integer "child_profile_id", null: false
    t.integer "profile_domain_id", null: false
    t.string "status", default: "suggested", null: false
    t.string "short_title", null: false
    t.text "description"
    t.integer "priority_rank"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "target_tags", default: []
    t.index ["child_profile_id", "status"], name: "index_child_goals_on_child_profile_id_and_status"
    t.index ["child_profile_id"], name: "index_child_goals_on_child_profile_id"
    t.index ["deleted_at"], name: "index_child_goals_on_deleted_at"
    t.index ["priority_rank"], name: "index_child_goals_on_priority_rank"
    t.index ["profile_domain_id"], name: "index_child_goals_on_profile_domain_id"
    t.index ["status"], name: "index_child_goals_on_status"
    t.index ["target_tags"], name: "index_child_goals_on_target_tags"
  end

  create_table "child_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "child_profile_id", null: false
    t.string "role", null: false
    t.boolean "is_primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_profile_id", "is_primary"], name: "index_child_memberships_on_child_profile_id_and_is_primary", unique: true, where: "is_primary = true"
    t.index ["child_profile_id"], name: "index_child_memberships_on_child_profile_id"
    t.index ["is_primary"], name: "index_child_memberships_on_is_primary"
    t.index ["role"], name: "index_child_memberships_on_role"
    t.index ["user_id", "child_profile_id"], name: "index_child_memberships_on_user_id_and_child_profile_id", unique: true
    t.index ["user_id"], name: "index_child_memberships_on_user_id"
  end

  create_table "child_profiles", force: :cascade do |t|
    t.integer "primary_caregiver_id", null: false
    t.string "name", null: false
    t.date "birth_date", null: false
    t.text "diagnosis_summary"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "preferred_contexts", default: []
    t.index ["deleted_at"], name: "index_child_profiles_on_deleted_at"
    t.index ["preferred_contexts"], name: "index_child_profiles_on_preferred_contexts"
    t.index ["primary_caregiver_id"], name: "index_child_profiles_on_primary_caregiver_id"
  end

  create_table "daily_recommendations", force: :cascade do |t|
    t.integer "child_profile_id", null: false
    t.date "date", null: false
    t.json "activity_template_ids", default: [], null: false
    t.datetime "computed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_profile_id", "date"], name: "index_daily_recommendations_on_child_profile_id_and_date", unique: true
    t.index ["child_profile_id"], name: "index_daily_recommendations_on_child_profile_id"
    t.index ["date"], name: "index_daily_recommendations_on_date"
  end

  create_table "onboarding_sessions", force: :cascade do |t|
    t.integer "child_profile_id", null: false
    t.integer "user_id", null: false
    t.string "status", default: "in_progress", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assessment_id"
    t.index ["assessment_id"], name: "index_onboarding_sessions_on_assessment_id"
    t.index ["child_profile_id", "status"], name: "index_onboarding_sessions_on_child_profile_id_and_status"
    t.index ["child_profile_id"], name: "index_onboarding_sessions_on_child_profile_id"
    t.index ["status"], name: "index_onboarding_sessions_on_status"
    t.index ["user_id"], name: "index_onboarding_sessions_on_user_id"
  end

  create_table "profile_domains", force: :cascade do |t|
    t.string "key", null: false
    t.string "label", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_profile_domains_on_key", unique: true
  end

  create_table "question_options", force: :cascade do |t|
    t.integer "question_id", null: false
    t.string "label", null: false
    t.integer "value", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "position"], name: "index_question_options_on_question_id_and_position"
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "code", null: false
    t.text "text", null: false
    t.string "domain"
    t.string "response_type", null: false
    t.integer "position"
    t.integer "profile_domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_questions_on_code", unique: true
    t.index ["domain"], name: "index_questions_on_domain"
    t.index ["profile_domain_id", "position"], name: "index_questions_on_profile_domain_id_and_position"
    t.index ["profile_domain_id"], name: "index_questions_on_profile_domain_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activity_logs", "activity_templates"
  add_foreign_key "activity_logs", "child_profiles"
  add_foreign_key "activity_templates", "profile_domains", column: "primary_target_id"
  add_foreign_key "ai_documents", "child_profiles"
  add_foreign_key "ai_documents", "onboarding_sessions"
  add_foreign_key "ai_documents", "users", column: "created_by_id"
  add_foreign_key "answers", "onboarding_sessions"
  add_foreign_key "answers", "question_options"
  add_foreign_key "answers", "questions"
  add_foreign_key "assessment_domains", "assessments", on_delete: :cascade
  add_foreign_key "assessment_domains", "profile_domains"
  add_foreign_key "child_domain_profiles", "child_profiles"
  add_foreign_key "child_domain_profiles", "profile_domains"
  add_foreign_key "child_goals", "child_profiles"
  add_foreign_key "child_goals", "profile_domains"
  add_foreign_key "child_memberships", "child_profiles"
  add_foreign_key "child_memberships", "users"
  add_foreign_key "child_profiles", "users", column: "primary_caregiver_id"
  add_foreign_key "daily_recommendations", "child_profiles"
  add_foreign_key "onboarding_sessions", "assessments"
  add_foreign_key "onboarding_sessions", "child_profiles"
  add_foreign_key "onboarding_sessions", "users"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "profile_domains"
end
