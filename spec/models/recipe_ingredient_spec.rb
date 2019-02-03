require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  describe "Associations" do
    it { should belong_to(:recipe) }
    it { should belong_to(:ingredient) }
  end
  describe 'Valid' do
    describe 'should be present' do
      it { should validate_presence_of(:recipe_id) }
      it { should validate_presence_of(:ingredient_id) }
    end
  end
  describe 'Invalid ::' do
    it 'shouldn\'t validate a blank RecipeIngredient.new' do
      expect(RecipeIngredient.new ).to_not be_valid
    end
  end
end
