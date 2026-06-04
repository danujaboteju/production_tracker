module Admin
  class FabricatorsController < ApplicationController
    before_action :set_fabricator, only: [:edit, :update]

    def index
      @fabricators = Fabricator.ordered
      @fabricator = Fabricator.new(active: true)
    end

    def create
      @fabricator = Fabricator.new(fabricator_params)

      if @fabricator.save
        redirect_to admin_fabricators_path, notice: "Fabricator / Welder added successfully."
      else
        @fabricators = Fabricator.ordered
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @fabricator.update(fabricator_params)
        redirect_to admin_fabricators_path, notice: "Fabricator / Welder updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_fabricator
      @fabricator = Fabricator.find(params[:id])
    end

    def fabricator_params
      params.require(:fabricator).permit(:name, :active)
    end
  end
end
