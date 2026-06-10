# frozen_string_literal: true

class CreateApiClients < ActiveRecord::Migration[7.2]
  def change
    create_table :api_clients do |t|
      t.string :name, null: false
      t.string :secret_digest, null: false
      t.string :secret_prefix, null: false, limit: 16

      t.timestamps
    end

    add_index :api_clients, :name, unique: true
    add_index :api_clients, :secret_digest, unique: true
  end
end
