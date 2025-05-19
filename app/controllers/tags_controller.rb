class TagsController < ApplicationController
    before_action :find_tag, only: [:show, :destroy]

    def index
        @q = current_user.tags.ransack(params[:q])
      @pagy, @tags = pagy_keyset(@q.result.includes(:user).ordered, limit: 21)
    end

    def show
        @pagy, @notes = pagy_keyset(@tag.notes.ordered, limit: 21)
    end
    
    def create
        tag = current_user.tags.build(tag_params)
        if tag.save
            render json: tag
        else
            render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
      @tag.destroy
        respond_to do |format|
        format.html { redirect_to tags_path, notice: "Tag deleted successfully" }
      end
    end

    private

    def tag_params
        params.require(:tag).permit(:name)
    end

    def find_tag
        @tag = Tag.find(params[:id])
    end
end
