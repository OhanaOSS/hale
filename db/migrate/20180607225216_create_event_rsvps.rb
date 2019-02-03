class CreateEventRsvps < ActiveRecord::Migration[5.2]
  def change
    create_table :event_rsvps do |t|
      t.integer :party_size, default: 1, :null => false
      t.integer :rsvp, default: 0, :null => false

      t.boolean :bringing_food, default: false
      t.references :recipe
      t.string :non_recipe_description
      t.integer :serving, default: 0

      t.references :member
      t.text :party_companions, array: true
      t.references :event, index: true
      t.text :rsvp_note

      t.timestamps
    end
  end
end