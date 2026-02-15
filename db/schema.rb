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

ActiveRecord::Schema[7.1].define(version: 2026_01_30_082007) do
  create_table "answers", force: :cascade do |t|
    t.integer "user_id"
    t.string "temporary_user_id"
    t.string "answer_text"
    t.integer "question_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "place_id"
    t.string "kind"
    t.integer "year"
    t.string "area_name"
    t.string "code"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "gobierto_budgets_associated_entities", force: :cascade do |t|
    t.string "entity_id", null: false
    t.string "name", null: false
    t.integer "ine_code", null: false
    t.string "slug", null: false
    t.index ["entity_id", "ine_code"], name: "index_associated_entities_on_entity_id_and_ine_code", unique: true
    t.index ["name", "ine_code"], name: "index_associated_entities_on_name_and_ine_code", unique: true
    t.index ["slug"], name: "index_gobierto_budgets_associated_entities_on_slug", unique: true
  end

  create_table "gobierto_cms_attachments", force: :cascade do |t|
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
    t.integer "gobierto_cms_page_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false
  end

  create_table "gobierto_cms_pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "body"
    t.integer "attachments_count", default: 0
    t.integer "parent_id"
    t.integer "position"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false
    t.index ["deleted_at"], name: "index_gobierto_cms_pages_on_deleted_at"
    t.index ["parent_id"], name: "index_gobierto_cms_pages_on_parent_id"
    t.index ["position"], name: "index_gobierto_cms_pages_on_position"
    t.index ["slug"], name: "index_gobierto_cms_pages_on_slug"
  end

  create_table "gobierto_participation_comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "body"
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["commentable_id"], name: "index_gobierto_participation_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_gobierto_participation_comments_on_commentable_type"
    t.index ["created_at"], name: "index_gobierto_participation_comments_on_created_at"
    t.index ["deleted_at"], name: "index_gobierto_participation_comments_on_deleted_at"
    t.index ["user_id"], name: "index_gobierto_participation_comments_on_user_id"
  end

  create_table "gobierto_participation_consultation_answers", force: :cascade do |t|
    t.integer "consultation_id", null: false
    t.string "answer"
    t.text "comment"
    t.integer "user_id", null: false
    t.integer "consultation_option_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["consultation_id", "user_id"], name: "gp_consultation_answers_unique_consultation_user", unique: true
    t.index ["consultation_id"], name: "gp_consultation_answers_consultation_id"
    t.index ["deleted_at"], name: "index_gobierto_participation_consultation_answers_on_deleted_at"
    t.index ["user_id"], name: "gp_consultation_answers_user_id"
  end

  create_table "gobierto_participation_consultation_options", force: :cascade do |t|
    t.integer "consultation_id", null: false
    t.string "option"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["consultation_id"], name: "gp_consultation_options_consultation_id"
    t.index ["deleted_at"], name: "index_gobierto_participation_consultation_options_on_deleted_at"
  end

  create_table "gobierto_participation_consultations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "body"
    t.string "slug"
    t.integer "kind", null: false
    t.datetime "open_until", precision: nil
    t.integer "site_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_gobierto_participation_consultations_on_deleted_at"
    t.index ["user_id"], name: "index_gobierto_participation_consultations_on_user_id"
  end

  create_table "gobierto_participation_ideas", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "body"
    t.string "slug"
    t.integer "site_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_gobierto_participation_ideas_on_created_at"
    t.index ["deleted_at"], name: "index_gobierto_participation_ideas_on_deleted_at"
    t.index ["user_id"], name: "index_gobierto_participation_ideas_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.string "domain"
    t.text "configuration_data"
    t.string "location_name"
    t.string "location_type"
    t.string "institution_url"
    t.string "institution_type"
    t.string "institution_email"
    t.string "institution_address"
    t.string "institution_document_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "place_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["place_id"], name: "index_subscriptions_on_place_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.string "remember_digest"
    t.string "password_reset_token"
    t.integer "place_id"
    t.string "document_type"
    t.string "document_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "verification_token"
    t.boolean "pro", default: false
    t.boolean "terms_of_service", default: false
    t.boolean "admin", default: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["place_id"], name: "index_users_on_place_id"
  end

  add_foreign_key "gobierto_participation_comments", "users"
  add_foreign_key "gobierto_participation_consultation_answers", "gobierto_participation_consultation_options", column: "consultation_option_id"
  add_foreign_key "gobierto_participation_consultation_answers", "gobierto_participation_consultations", column: "consultation_id"
  add_foreign_key "gobierto_participation_consultation_answers", "users"
  add_foreign_key "gobierto_participation_consultation_options", "gobierto_participation_consultations", column: "consultation_id"
  add_foreign_key "gobierto_participation_consultations", "users"
  add_foreign_key "gobierto_participation_ideas", "users"
  add_foreign_key "subscriptions", "users"
end
