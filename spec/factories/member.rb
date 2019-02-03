# 
FactoryBot.define do

  factory :member do
    name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    email { Faker::Internet.email }
    password "password"
    confirmed_at Date.new

    factory :member_profile do
    
      nickname { Faker::Name.first_name }
      # samples two schemas
      contacts { [{cell: Faker::PhoneNumber.cell_phone,home: Faker::PhoneNumber.cell_phone,work: Faker::PhoneNumber.cell_phone}, {cell: Faker::PhoneNumber.cell_phone}].sample }
      # samples two schemas
      addresses { [{"type": ["home", "vacation"].sample, "line-1": Faker::Address.street_address,"line-2": "","city": Faker::Address.city,"state": Faker::Address.state_abbr,"postal": Faker::Address.postcode},{"type": "work", "line-1": Faker::Address.street_address,"line-2": "Building #{Faker::Address.building_number}","city": Faker::Address.city,"state": Faker::Address.state_abbr,"postal": Faker::Address.postcode},{"type":["home", "vacation"].sample, "line-1": Faker::Address.street_address,"line-2": "","city": Faker::Address.city,"state": Faker::Address.state_abbr,"postal": Faker::Address.postcode}].sample }
      gender { [0,1,2].sample }
      bio {[Faker::FamilyGuy.quote, Faker::HarryPotter.quote].sample}
      birthday { Faker::Date.birthday(18, 65).to_datetime }
      instagram {"@foobar"}

    end
  end
  
end

