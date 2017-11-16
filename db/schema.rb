# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171116162535) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.integer "image_id"
    t.string "phone"
    t.integer "fan_id"
    t.integer "artist_id"
    t.integer "venue_id"
    t.integer "account_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_name"
    t.string "display_name"
  end

  create_table "artist_genres", force: :cascade do |t|
    t.integer "artist_id"
    t.integer "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artists", force: :cascade do |t|
    t.string "about"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fan_genres", force: :cascade do |t|
    t.integer "fan_id"
    t.integer "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fans", force: :cascade do |t|
    t.string "bio"
    t.string "address"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "followers", force: :cascade do |t|
    t.integer "by_id"
    t.integer "to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", force: :cascade do |t|
    t.string "base64"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phone_validations", force: :cascade do |t|
    t.string "phone"
    t.boolean "is_validated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "info"
  end

  create_table "user_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "name"
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_id"
    t.string "twitter_id"
    t.string "register_phone"
  end

  create_table "venue_dates", force: :cascade do |t|
    t.integer "venue_id"
    t.date "begin_date"
    t.date "end_date"
    t.integer "is_available"
    t.integer "price"
    t.integer "booking_notice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venue_emails", force: :cascade do |t|
    t.integer "venue_id"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venue_office_hours", force: :cascade do |t|
    t.integer "venue_id"
    t.integer "day"
    t.time "begin_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venue_operating_hours", force: :cascade do |t|
    t.integer "venue_id"
    t.integer "day"
    t.time "begin_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venues", force: :cascade do |t|
    t.string "address"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "phone"
    t.string "fax"
    t.string "bank_name"
    t.string "account_bank_number"
    t.string "account_bank_routing_number"
    t.integer "capacity"
    t.integer "num_of_bathrooms"
    t.integer "min_age"
    t.integer "venue_type"
    t.boolean "has_bar"
    t.integer "located"
    t.string "dress_code"
    t.boolean "has_vr"
    t.string "audio_description"
    t.string "lighting_description"
    t.string "stage_description"
  end

end
