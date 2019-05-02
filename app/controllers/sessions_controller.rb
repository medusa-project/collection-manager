class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token
  skip_before_action :require_logged_in

  def new
    set_return_url
    if Rails.env.production?
      redirect_to(shibboleth_login_path(Settings.host))
    else
      redirect_to('/auth/developer')
    end
  end

  def create
    auth_hash = request.env['omniauth.auth']
    if auth_hash and auth_hash[:uid]
      return_url = clear_and_return_return_path
      user = User.find_or_create_by!(uid: auth_hash[:uid], email: auth_hash[:info][:email])
      set_current_user(user)
      redirect_to return_url
    else
      redirect_to login_url
    end
  end

  def destroy
    unset_current_user
    clear_and_return_return_path
    redirect_to root_url
  end

  private

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end

  def clear_and_return_return_path
    return_url = session[:login_return_uri] || session[:login_return_referer] || root_path
    session[:login_return_uri] = session[:login_return_referer] = nil
    reset_session
    return_url
  end

  def set_return_url
    session[:login_return_referer] = request.env['HTTP_REFERER']
  end

end