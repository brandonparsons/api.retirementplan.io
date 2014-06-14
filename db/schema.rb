# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140413042005) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "hstore"

  create_table "authentications", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "uid",           null: false
    t.string   "provider",      null: false
    t.text     "oauth_token"
    t.datetime "oauth_expires"
    t.uuid     "user_id",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", using: :btree
  add_index "authentications", ["user_id"], name: "index_authentications_on_user_id", using: :btree

  create_table "etfs", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "ticker",      null: false
    t.text     "description", null: false
    t.uuid     "security_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "etfs", ["security_id"], name: "index_etfs_on_security_id", using: :btree
  add_index "etfs", ["ticker"], name: "index_etfs_on_ticker", unique: true, using: :btree

  create_table "expenses", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "description",                 null: false
    t.decimal  "amount",                      null: false
    t.string   "frequency",                   null: false
    t.datetime "ends"
    t.datetime "onetime_on"
    t.text     "notes",       default: "",    null: false
    t.boolean  "is_added",    default: false, null: false
    t.uuid     "user_id",                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "expenses", ["is_added"], name: "index_expenses_on_is_added", using: :btree
  add_index "expenses", ["user_id"], name: "index_expenses_on_user_id", using: :btree

  create_table "portfolios", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.decimal  "expected_return",               null: false
    t.decimal  "expected_std_dev",              null: false
    t.json     "weights",          default: {}, null: false
    t.hstore   "data"
    t.uuid     "user_id",                       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "portfolios", ["data"], name: "index_portfolios_on_data", using: :gin
  add_index "portfolios", ["user_id"], name: "index_portfolios_on_user_id", unique: true, using: :btree

  create_table "questionnaires", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.float    "pratt_arrow_low",            null: false
    t.float    "pratt_arrow_high",           null: false
    t.integer  "age",                        null: false
    t.integer  "sex",                        null: false
    t.integer  "no_people",                  null: false
    t.integer  "real_estate_val",            null: false
    t.integer  "saving_reason",              null: false
    t.integer  "investment_timeline",        null: false
    t.integer  "investment_timeline_length", null: false
    t.integer  "economy_performance",        null: false
    t.integer  "financial_risk",             null: false
    t.integer  "credit_card",                null: false
    t.integer  "pension",                    null: false
    t.integer  "inheritance",                null: false
    t.integer  "bequeath",                   null: false
    t.integer  "degree",                     null: false
    t.integer  "loan",                       null: false
    t.integer  "forseeable_expenses",        null: false
    t.integer  "married",                    null: false
    t.integer  "emergency_fund",             null: false
    t.integer  "job_title",                  null: false
    t.integer  "investment_experience",      null: false
    t.uuid     "user_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questionnaires", ["user_id"], name: "index_questionnaires_on_user_id", unique: true, using: :btree

  create_table "retirement_simulation_parameters", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.boolean  "user_is_male"
    t.boolean  "married"
    t.integer  "male_age"
    t.integer  "female_age"
    t.boolean  "user_retired"
    t.integer  "retirement_age_male"
    t.integer  "retirement_age_female"
    t.decimal  "assets"
    t.decimal  "expenses_inflation_index"
    t.decimal  "life_insurance"
    t.decimal  "income"
    t.decimal  "current_tax_rate"
    t.decimal  "salary_increase"
    t.decimal  "retirement_income"
    t.decimal  "retirement_expenses"
    t.decimal  "retirement_tax_rate"
    t.decimal  "income_inflation_index"
    t.boolean  "include_home"
    t.decimal  "home_value"
    t.decimal  "sell_house_in"
    t.decimal  "new_home_relative_value"
    t.decimal  "expenses_multiplier"
    t.decimal  "fraction_for_single_income"
    t.uuid     "user_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "retirement_simulation_parameters", ["user_id"], name: "index_retirement_simulation_parameters_on_user_id", unique: true, using: :btree

  create_table "securities", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "ticker",                      null: false
    t.string   "asset_class",                 null: false
    t.string   "asset_type",                  null: false
    t.decimal  "mean_return",                 null: false
    t.decimal  "std_dev",                     null: false
    t.decimal  "implied_return",              null: false
    t.decimal  "returns",        default: [], null: false, array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "securities", ["asset_class"], name: "index_securities_on_asset_class", using: :btree
  add_index "securities", ["ticker"], name: "index_securities_on_ticker", unique: true, using: :btree

  create_table "users", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name",                                 null: false
    t.string   "email",                                null: false
    t.string   "image_url"
    t.string   "password_digest"
    t.string   "authentication_token"
    t.boolean  "admin",                default: false, null: false
    t.boolean  "from_oauth",           default: false, null: false
    t.integer  "sign_in_count",        default: 0,     null: false
    t.datetime "last_sign_in_at"
    t.datetime "accepted_terms"
    t.datetime "confirmed_at"
    t.hstore   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["data"], name: "index_users_on_data", using: :gin
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
