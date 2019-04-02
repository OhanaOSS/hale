class ChangeMembersAddressContactHashesToArray < ActiveRecord::Migration[5.2]
  def change
    change_column(:members, :contacts, :jsonb, options = {
      :default => "[]", 
      :null => false
    })
    change_column(:members, :addresses, :jsonb, options = {
      :default => "[]", 
      :null => false
    })
  end
end
