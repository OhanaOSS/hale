class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.references :notifiable, null: false, polymorphic: true, index: true
      t.references :member, null: false, index: true
      t.boolean :mentioned, default: false
      t.boolean :viewed, default: false
      t.timestamps
    end
  end
end
