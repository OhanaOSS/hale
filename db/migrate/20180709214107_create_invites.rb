class CreateInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :invites do |t|
      t.string :email 
      t.references :family
      t.integer :sender_id
      t.integer :recipient_id, null: true, default: nil
      t.string :token, index: true
      t.datetime :sent_at, default: nil
      t.datetime :accepted_at, default: nil
      t.timestamps
    end
  end
end
