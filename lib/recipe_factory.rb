class RecipeFactory
  def initialize(recipe_params)
    recipe_params = recipe_params["attributes"].to_h if recipe_params["attributes"].present?
    @title = recipe_params["title"].to_s if recipe_params["title"].present?

    @description = recipe_params["description"].to_s  if recipe_params["description"].present?
    if recipe_params["ingredients_list"].present?
      @ingredients_object_array = []
      @ingredients = recipe_params["ingredients_list"].to_a.each do |ingredient|
        i = Ingredient.find_or_create_by(title: ingredient)
        @ingredients_object_array << i
      end
    end

    if recipe_params["tags_list"].present?
      @tags_object_array = []
      @tags = recipe_params["tags_list"].each do |tag|   
        t = tag
        tag = Tag.find_or_create_by(title: tag["title"].titleize)
        if tag.description == nil
          tag.update_attributes(description: t["description"])
        end
        if t["mature"].present? && ActiveModel::Type::Boolean.new.cast(t["mature"]) == true
          tag.update_attributes(mature: ActiveModel::Type::Boolean.new.cast(t["mature"]))
        end
        @tags_object_array << tag
      end
    end
    @steps = recipe_params["steps"] if recipe_params["steps"].present?
    @member = Member.find(recipe_params["member_id"].to_i) if recipe_params["member_id"].present?

  end
  
  def result
    Recipe.new({
      title: @title,
      description: @description,
      member_id: @member.id,
      steps: @steps.to_h,
      ingredients_list: @ingredients_object_array.map {|ingredient| ingredient.title},
      tags_list: @tags_object_array.map {|tag| tag.title}
    })
  end

  def factory_callback(id)
    joins = []
    @tags_object_array.each do |tag|
      joins << RecipeTag.create(tag_id: tag.id, recipe_id: id)
    end

    @ingredients_object_array.each do |ingredient|
      joins << RecipeIngredient.create(ingredient_id: ingredient.id, recipe_id: id)
    end
    return joins
  end
  def update_callback(id)
    current_ingredients = []
    current_tags = []

    if @tags_object_array.present?
      @tags_object_array.each do |tag|
        current_tags << RecipeTag.find_or_create_by(tag_id: tag.id, recipe_id: id)
      end
    end

    if @ingredients_object_array.present?
      @ingredients_object_array.each do |ingredient|
        current_ingredients << RecipeIngredient.find_or_create_by(ingredient_id: ingredient.id, recipe_id: id)
      end
    end

    RecipeTag.where.not(id: current_tags.pluck(:id).sort).delete_all unless current_tags.empty?
    RecipeIngredient.where.not(id: current_ingredients.pluck(:id).sort).delete_all unless current_ingredients.empty?
    return [current_ingredients,current_tags].flatten
  end

end