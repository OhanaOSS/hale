class CreateFamilyConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :family_configs do |t|
      t.references :family, null: false
      t.boolean :authorization_enabled, default: true, null: false
      t.timestamps
    end
  end
end
