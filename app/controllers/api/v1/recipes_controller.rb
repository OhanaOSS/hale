class API::V1::RecipesController < ApplicationController
  before_action :authenticate_api_v1_member!
  def index
    @recipes = policy_scope(Recipe)
    render json: @recipes, each_serializer: RecipeSerializer, adapter: :json_api
  end
  def search
    begin
      query = search_params[:query]
      type = search_params[:type]
      # Searching and Processing Query based on Type
      if type == "tag"
        tag_ids = Tag.where("lower(title) LIKE :search OR lower(description) LIKE :search", search: "%#{query.downcase}%").pluck(:id).uniq
        @recipes = policy_scope(Recipe).where(id: RecipeTag.where(tag_id: tag_ids).pluck(:recipe_id).uniq )
      elsif type == "ingredient"
        ingredient_ids = Ingredient.where("lower(title) LIKE :search", search: "%#{query.downcase}%").pluck(:id).uniq
        @recipes = policy_scope(Recipe).where(id: RecipeIngredient.where(ingredient_id: ingredient_ids).pluck(:recipe_id).uniq )
      elsif type == "recipe"
        @recipes = policy_scope(Recipe).where("lower(title) LIKE :search OR lower(description) LIKE :search", search: "%#{query.downcase}%").uniq
      else
        # Request didn't match any preset types.
        render json: {:query => query, :type => type, :message => "Request type likely didn't match 'tag', 'ingredient, or 'recipe'."}, status: :bad_request
        return
      end
      # Formatting for Render
      if @recipes == [] || @recipes.nil?
        render json: {}, status: :no_content
      else
        render json: @recipes, each_serializer: RecipeSerializer, adapter: :json_api
      end
    rescue Pundit::NotAuthorizedError
      @recipes.errors.add(:id, :forbidden, message: "current user is not authorized to search this post in family id: #{@recipes.family_id}")
      render :json => { errors: @recipes.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end #rescue
  end
  def show
    begin
      @recipe = Recipe.find(params[:id])
      authorize @recipe
      render json: @recipe, serializer: RecipeSerializer, adapter: :json_api
    rescue Pundit::NotAuthorizedError
      @recipe.errors.add(:id, :forbidden, message: "current user is not authorized to view this recipe")
      render :json => { errors: @recipe.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def create
    begin
      @recipe = RecipeFactory.new(recipe_params.except(:media)).result
      authorize @recipe
      if @recipe.save
        @recipe.media.attach(recipe_params[:attributes][:media]) if recipe_params[:attributes][:media].present?
        # Callback to have access to @recipe.id to create join_tables.
        RecipeFactory.new(recipe_params.except(:media)).factory_callback(@recipe.id)
        render json: @recipe, serializer: RecipeSerializer, adapter: :json_api
      else
        render json: { errors: @recipe.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @recipe.errors.add(:id, :forbidden, message: "current user is not authorized to create this recipe")
      render :json => { errors: @recipe.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

  def update
    begin
      @recipe = Recipe.find(params[:id])
      authorize @recipe
      @recipe.assign_attributes(recipe_params)
      if @recipe.save
        RecipeFactory.new(recipe_params.except(:media)).update_callback(@recipe.id)
        render json: @recipe
      else
        render json: { errors: @recipe.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      @recipe.errors.add(:id, :forbidden, message: "current user is not authorized to update this recipe")
      render :json => { errors: @recipe.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
  end

   def destroy
    begin
      @recipe = Recipe.find(params[:id])
      authorize @recipe
      @recipe.destroy
      render json: {}, status: :no_content
    rescue Pundit::NotAuthorizedError
      @recipe.errors.add(:id, :forbidden, message: "current user is not authorized to delete this recipe")
      render :json => { errors: @recipe.errors.full_messages }, :status => :forbidden
    rescue ActiveRecord::RecordNotFound
      render :json => {}, :status => :not_found
    end
   end

  private
    def recipe_params
      params[:recipe][:ingredients_list] ||= []
      params.require(:recipe).permit(attributes: [
        :title,
        :description,
        :member_id,
        :media,
        :ingredients_list => [],
        tags_list: [:title, :description, :mature],
        steps:{
          preparation: [:instruction, :time_length, {:ingredients => []}],
          cooking: [:instruction, :time_length, {:ingredients => []}],
          post_cooking: [:instruction, :time_length, {:ingredients => []}]
        }])
    end
    def search_params
      params.require(:filter).permit(:query, :type)
    end
end
