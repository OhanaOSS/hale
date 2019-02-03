class CreateReactions < ActiveRecord::Migration[5.2]
  def change
    create_table :reactions do |t|
      t.references :member, null: false, index: true
      t.integer :emotive
      t.references :interaction, null: false, polymorphic: true, index: true

      t.timestamps
    end
  end
end
