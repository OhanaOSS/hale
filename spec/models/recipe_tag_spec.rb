require 'rails_helper'

RSpec.describe RecipeTag, type: :model do
  describe "Associations" do
    it { should belong_to(:recipe) }
    it { should belong_to(:tag) }
  end
  describe 'Valid' do
    describe 'should be present' do
      it { should validate_presence_of(:recipe_id) }
      it { should validate_presence_of(:tag_id) }
    end
  end
  describe 'Invalid ::' do
    it 'shouldn\'t validate a blank RecipeTag.new' do
      expect(RecipeTag.new ).to_not be_valid
    end
  end
end
