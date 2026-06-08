module Admin
  class FabricatorsController < ApplicationController
    before_action :set_fabricator, only: [:edit, :update]
    before_action :set_operation_options, only: [:index, :create, :edit, :update]

    def index
      @fabricators = Fabricator.includes(:fabricator_operations).ordered
      @fabricator = Fabricator.new(active: true)
    end

    def create
      @fabricator = Fabricator.new(fabricator_params)

      ActiveRecord::Base.transaction do
        @fabricator.save!
        sync_operation_assignments(@fabricator)
      end

      redirect_to admin_fabricators_path, notice: "Team Member added successfully."
    rescue ActiveRecord::RecordInvalid
      @fabricators = Fabricator.includes(:fabricator_operations).ordered
      render :index, status: :unprocessable_entity
    end

    def edit
    end

    def update
      ActiveRecord::Base.transaction do
        @fabricator.update!(fabricator_params)
        sync_operation_assignments(@fabricator)
      end

      redirect_to admin_fabricators_path, notice: "Team Member updated successfully."
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    private

    def set_fabricator
      @fabricator = Fabricator.find(params[:id])
    end

    def set_operation_options
      @operation_options = JobProcess::PROCESS_OPTIONS
    end

    def fabricator_params
      params.require(:fabricator).permit(:name, :active)
    end

    def selected_operation_codes
      Array(params[:fabricator][:operation_codes]).reject(&:blank?) & JobProcess::PROCESS_OPTIONS.keys
    end

    def sync_operation_assignments(fabricator)
      operation_codes = selected_operation_codes

      fabricator.fabricator_operations.where.not(operation_code: operation_codes).destroy_all

      operation_codes.each do |operation_code|
        fabricator.fabricator_operations.find_or_create_by!(operation_code: operation_code)
      end
    end
  end
end
