class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create], raise: false

  def new
  end

  def create
    username = params[:username].to_s.strip.downcase
    password = params[:password].to_s

    user = User.find_by(username: username)

    if user&.authenticate(password)
      start_new_session_for user
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Try another username or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end