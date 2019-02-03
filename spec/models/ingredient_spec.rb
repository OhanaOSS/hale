require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe "Associations" do
    it { should have_many(:recipe_ingredients) }
    it { should have_many(:recipes) }
  end
  describe 'Valid ::' do
    it 'FactoryBot factory should be valid' do
      expect(FactoryBot.build(:ingredient) ).to be_valid
    end
  end
  describe 'Invalid ::' do
    it 'shouldn\'t validate a blank Tag.new' do
      expect(Ingredient.new ).to_not be_valid
    end
  end
end
