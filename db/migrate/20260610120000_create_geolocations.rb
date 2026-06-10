# frozen_string_literal: true

class CreateGeolocations < ActiveRecord::Migration[7.2]
  def change
    create_table :geolocations do |t|
      t.string :query_type, null: false
      t.string :query_value, null: false
      t.string :resolved_ip
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :country_name
      t.string :country_code, limit: 2
      t.string :region_name
      t.string :city
      t.string :provider, null: false
      t.jsonb :raw_response, default: {}

      t.timestamps
    end

    add_index :geolocations, %i[query_type query_value], unique: true
    add_index :geolocations, :resolved_ip
  end
end
