require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe "Associations" do
    it { should have_many(:recipe_ingredients).class_name('RecipeIngredient') }
    it { should have_many(:ingredients) }
    it { should have_many(:recipe_tags).class_name('RecipeTag') }
    it { should have_many(:tags) }
    it { should belong_to(:member) }
  end
  it_behaves_like 'interaction'
  it_behaves_like 'media'
  describe "valid" do
    it 'FactoryBot factory should be valid' do
      expect(FactoryBot.build(:recipe, member_id: FactoryBot.create(:family_member).member_id)).to be_valid
    end
  end
  describe "invalid" do
    it "empty news should be invalid" do
      expect(Recipe.new).to_not be_valid
    end
    describe ":: nils" do
      it "all nils should be invalid :: title" do
        recipe = Recipe.new(title: nil)
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: description" do
        recipe = Recipe.new(description: nil)
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: steps" do
        recipe = Recipe.new(steps: nil)
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: ingredients_list" do
        recipe = Recipe.new(ingredients_list: nil)
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: tags_list" do
        recipe = Recipe.new(tags_list: nil)
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        recipe = Recipe.new(member_id: nil)
        expect(recipe).to_not be_valid
      end
    end
    describe ":: emptys" do
      it "all nils should be invalid :: title" do
        recipe = Recipe.new(title: "")
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: description" do
        recipe = Recipe.new(description: "")
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: steps" do
        recipe = Recipe.new(steps: "")
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: ingredients_list" do
        recipe = Recipe.new(ingredients_list: "")
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: tags_list" do
        recipe = Recipe.new(tags_list: "")
        expect(recipe).to_not be_valid
      end
      it "all nils should be invalid :: member_id" do
        recipe = Recipe.new(member_id: "")
        expect(recipe).to_not be_valid
      end
    end
  end
end
