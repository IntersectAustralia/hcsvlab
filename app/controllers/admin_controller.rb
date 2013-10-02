class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorizeAdmin

  def index
  end

  private

  def authorizeAdmin
    authorize! :manage, AdminController
  end

end
