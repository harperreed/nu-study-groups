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

ActiveRecord::Schema[7.1].define(version: 2025_11_18_164710) do
  create_table "course_teachers", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "user_id"], name: "index_course_teachers_on_course_id_and_user_id", unique: true
    t.index ["course_id"], name: "index_course_teachers_on_course_id"
    t.index ["user_id"], name: "index_course_teachers_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.string "semester", null: false
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "semester", "year"], name: "index_courses_on_code_and_semester_and_year", unique: true
  end

  create_table "study_group_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_group_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at", null: false
    t.datetime "approved_at"
    t.integer "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_study_group_memberships_on_approved_by_id"
    t.index ["status"], name: "index_study_group_memberships_on_status"
    t.index ["study_group_id"], name: "index_study_group_memberships_on_study_group_id"
    t.index ["user_id", "study_group_id"], name: "index_study_group_memberships_on_user_id_and_study_group_id", unique: true
    t.index ["user_id"], name: "index_study_group_memberships_on_user_id"
  end

  create_table "study_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "group_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "course_id", null: false
    t.integer "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_study_groups_on_course_id"
    t.index ["creator_id"], name: "index_study_groups_on_creator_id"
    t.index ["group_type"], name: "index_study_groups_on_group_type"
    t.index ["status"], name: "index_study_groups_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "course_teachers", "courses"
  add_foreign_key "course_teachers", "users"
  add_foreign_key "study_group_memberships", "study_groups"
  add_foreign_key "study_group_memberships", "users"
  add_foreign_key "study_group_memberships", "users", column: "approved_by_id"
  add_foreign_key "study_groups", "courses"
  add_foreign_key "study_groups", "users", column: "creator_id"
end
