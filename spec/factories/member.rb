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
      # strange error
      addresses { [{"address-type": ["home", "vacation"].sample, "prefix": ["N","S","W","E", ""].sample, "number": Faker::Address.building_number.to_s, "street": Faker::Address.street_name, "type": Faker::Address.street_suffix, "sec-unit-num": rand(1..10).to_s, "sec-unit-type": ["Apt.", "Bld.", "Dorm."].sample, "city": Faker::Address.city,"state": Faker::Address.state_abbr,"zip": Faker::Address.zip_code.to_s}][0]}
      gender { [0,1,2].sample }
      bio {[Faker::TvShows::FamilyGuy.quote, Faker::Movies::HarryPotter.quote].sample}
      birthday { Faker::Date.birthday(18, 65).to_datetime }
      instagram {"@foobar"}

    end
  end
  
end

