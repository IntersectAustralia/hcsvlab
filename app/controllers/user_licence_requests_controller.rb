class UserLicenceRequestsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @requests = current_user.user_licence_requests.where(approved: false)
  end

  def approve_request
    @request = UserLicenceRequest.find(params[:id])
    email = @request.user_email
    coll_name = @request.request.name
    user = @request.user
    @request.approve

    Notifier.notify_user_of_approved_collection_request(user, coll_name).deliver
    redirect_to(user_licence_requests_path, :notice => "Access request for '#{email}' to #{coll_name} has been approved")
  end

  def reject_request
    @request = UserLicenceRequest.find(params[:id])
    reason = params[:reason]
    email = @request.user_email
    coll_name = @request.request.name
    user = @request.user
    @request.destroy

    Notifier.notify_user_of_rejected_collection_request(user, coll_name, reason).deliver
    redirect_to(user_licence_requests_path, :notice => "Access request for '#{email}' to #{coll_name} has been rejected")
  end

  def cancel_request
    @request = UserLicenceRequest.find(params[:id]).destroy

    redirect_to(account_licence_agreements_path, :notice => "Access request cancelled successfully")
  end

end