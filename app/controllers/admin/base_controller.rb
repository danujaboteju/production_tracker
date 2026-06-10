module Admin
  class BaseController < ApplicationController
    before_action :require_authentication
    before_action :require_admin
  end
end
