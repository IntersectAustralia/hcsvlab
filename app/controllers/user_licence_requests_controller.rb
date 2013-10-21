class UserLicenceRequestsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @requests = UserLicenceRequest.where(:owner_email => current_user.email)
  end

end