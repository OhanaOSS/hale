require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "Associations" do
    it { should have_many(:recipes) }
    it { should have_many(:recipe_tags) }
  end
  describe 'Valid ::' do
    it 'FactoryBot factory should be valid' do
      expect(FactoryBot.build(:tag) ).to be_valid
    end
  end
  describe 'Invalid ::' do
    it 'shouldn\'t validate a blank Tag.new' do
      expect(Tag.new ).to_not be_valid
    end
  end
end
