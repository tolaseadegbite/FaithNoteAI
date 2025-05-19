class CategoriesController < ApplicationController
    before_action :find_category, only: [:show, :edit, :update, :destroy]

    def index
      # @categories = current_user.categories.ordered
      @q = current_user.categories.ransack(params[:q])
      @pagy, @categories = pagy_keyset(@q.result.includes(:user).ordered, limit: 21)
    end

    def show
      # @notes = @category.notes.ordered
      @pagy, @notes = pagy_keyset(@category.notes.ordered, limit: 21)
    end

    def new
      @category = Category.new
    end

    def create
      @category = current_user.categories.build(categories_param)
      if @category.save
        respond_to do |format|
          format.html { redirect_to @category, notice: "Category created successfully" }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(categories_param)
        respond_to do |format|
          format.html { redirect_to @category, notice: "Category created successfully" }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category.destroy
        respond_to do |format|
        format.html { redirect_to categories_path, notice: "Category deleted successfully" }
      end
    end
    



    private

      def categories_param
        params.require(:category).permit(:name)
      end

      def find_category
        @category = Category.find(params[:id])
      end
end
