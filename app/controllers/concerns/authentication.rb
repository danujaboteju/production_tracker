module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?, :current_user
  end

  private

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    redirect_to new_session_path, alert: "Please sign in." unless authenticated?
  end

  def require_admin
    return if current_user&.admin?

    redirect_to new_session_path, alert: "You are not authorized to access admin."
  end

  def start_new_session_for(user)
    session_record = user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    Current.session = session_record
    cookies.signed.permanent[:session_id] = {
      value: session_record.id,
      httponly: true,
      same_site: :lax
    }
  end

  def terminate_session
    Current.session&.destroy
    Current.session = nil
    cookies.delete(:session_id)
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end
end
