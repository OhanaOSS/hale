class AddToMember < ActiveRecord::Migration[5.2]
  def change
    change_table :members do |t|
      ## User Info
      t.string :surname
      t.json :contacts, default: "{}"
      t.json :addresses, default: "{}"
      t.integer :gender
      t.text :bio
      t.date :birthday
      ## Social Media
      t.string :instagram

    end
  end
end
