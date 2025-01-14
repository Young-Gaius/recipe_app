class RecipeFoodsController < ApplicationController
  def new
    @recipe = Recipe.find(params[:recipe_id])
    @recipe_food = RecipeFood.new
    @foods = current_user.foods
  end

  def create
    @recipe_food = RecipeFood.where(food_id: params[:recipe_food]['food_id'],
                                    recipe_id: params[:recipe_food]['recipe_id']).first
    if @recipe_food
      @recipe_food.quantity += params[:recipe_food]['quantity'].to_i
      @recipe_food.save
    else
      @recipe = RecipeFood.new(recipe_food_params)
      @recipe.save
    end
    redirect_to recipe_path(params[:recipe_id].to_i)
  end

  def general_shopping_list
    @total = 0
    @all_recipe_foods = get_recipe_foods
    @shopping_list = what_food_to_buy?(@all_recipe_foods)
    @shopping_list.each do |item|
      @total += item[:price]
    end
    @total
  end

  private

  def recipe_food_params
    params.require(:recipe_food).permit(:quantity, :food_id, :recipe_id)
  end

  def this_food?(base, item)
    @food_element = nil
    base.each do |element|
      @food_element = element if item == element[:food]
    end
    @food_element
  end

  def get_recipe_foods
    @all_foods = []
    @all_recipes = current_user.recipes
    @all_recipes.each do |recipe_item|
      recipe_item.recipe_foods.each do |recipe_food_item|
        @food = this_food?(@all_foods, recipe_food_item.food.name)
        if @food
          @index_food = @all_foods.index(@food)
          @all_foods[@index_food][:quantity] += recipe_food_item.quantity
          @all_foods[@index_food][:price] = recipe_food_item.food.price * @all_foods[@index_food][:quantity]
        else
          @food = {} if @food.nil?
          @food[:id] = recipe_food_item.food.id
          @food[:food] = recipe_food_item.food.name
          @food[:quantity] =
            recipe_food_item.quantity.to_i
          @food[:price] = recipe_food_item.food.price * @food[:quantity]
          @food[:unit] = recipe_food_item.food.measurement_unit
          @all_foods.push(@food)
        end
      end
    end
    @all_foods
  end

  def what_food_to_buy?(all_recipes_foods)
    @food_to_buy = []
    all_recipes_foods.each_with_index do |recipe_item, _index|
      current_food = Food.where(user: current_user, id: recipe_item[:id]).first
      if current_food.quantity.to_i < recipe_item[:quantity].to_i
        recipe_item[:quantity] -= current_food.quantity
        @food_to_buy.push(recipe_item)
      end
    end
    @food_to_buy
  end
end
