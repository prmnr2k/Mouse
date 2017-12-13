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

ActiveRecord::Schema.define(version: 20171213061438) do

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

  create_table "event_collaborators", force: :cascade do |t|
    t.integer "event_id"
    t.integer "collaborator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_genres", force: :cascade do |t|
    t.integer "event_id"
    t.integer "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.string "tagline"
    t.string "description"
    t.datetime "funding_from"
    t.datetime "funding_to"
    t.integer "funding_goal"
    t.integer "creator_id"
    t.integer "artist_id"
    t.integer "venue_id"
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

