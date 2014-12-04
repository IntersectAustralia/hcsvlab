class UsersController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @users = User.deactivated_or_approved
    @approved_researcher_count = User.approved_researchers.count
    @total_weekly_visits_count = UserHelper::get_total_weekly_visits
    @total_weekly_duration_count = UserHelper::get_total_weekly_duration
    @average_weekly_visits_count = UserHelper::get_average_frequency_visits
    @average_weekly_duration_count = UserHelper::get_average_weekly_duration
  end

  def show
  end

  def admin

  end

  def access_requests
    @users = User.pending_approval
  end

  def deactivate
    if !@user.check_number_of_superusers(params[:id], current_user.id) 
      redirect_to(@user, :alert => "You cannot deactivate this account as it is the only account with #{Role::SUPERUSER_ROLE} privileges.")
    else
      @user.deactivate
      redirect_to(@user, :notice => "The user has been deactivated.")
    end
  end

  def activate
    @user.activate
    redirect_to(@user, :notice => "The user has been activated.")
  end

  def reject
    @user.reject_access_request
    @user.destroy
    redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was rejected.")
  end

  def reject_as_spam
    @user.reject_access_request
    redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was rejected and this email address will be permanently blocked.")
  end

  def edit_role
    if @user == current_user
      flash.now[:alert] = "You are changing the role of the user you are logged in as."
    elsif @user.rejected?
      redirect_to(users_path, :alert => "Role can not be set. This user has previously been rejected as a spammer.")
    end
    @roles = Role.by_name
  end

  def edit_approval
    @roles = Role.by_name
  end

  def update_role
    if params[:user][:role_id].blank?
        redirect_to(edit_role_user_path(@user), :alert => "Please select a role for the user.")
    else
      @user.role_id = params[:user][:role_id]
      if !@user.check_number_of_superusers(params[:id], current_user.id)
        redirect_to(edit_role_user_path(@user), :alert => "Only one superuser exists. You cannot change this role.")
      elsif @user.save
        redirect_to(@user, :notice => "The role for #{@user.email} was successfully updated.")
      end
    end
  end

  def approve
    if !params[:user][:role].blank?
      @user.role_id = params[:user][:role]
      @user.save
      @user.approve_access_request

      redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was approved.")
    else
      redirect_to(edit_approval_user_path(@user), :alert => "Please select a role for the user.")
    end
  end

  #
  # Create and send licence request for the given collection
  #
  def send_licence_request
    type = params[:type]
    coll_id = params[:coll_id]

    @request = ::UserLicenceRequest.new
    @request.user = current_user
    if type == "collection"
      coll = Collection.find(coll_id)
      @request.request_type = "collection"
      @request.request_id = coll.id
      @request.owner_id = coll.owner_id
    else
      list = CollectionList.find(coll_id)
      @request.request_type = "collection_list"
      @request.request_id = list.id
      @request.owner_id  = list.owner_id
    end
    @request.approved = false
    @request.save!

    Notifier.notify_data_owner_of_user_licence_request(@request).deliver
    redirect_to(account_licence_agreements_path, :notice => "An access request was successfully sent to the collection owner.")
  end

  #
  # Accept the licence for the given collection
  #
  def accept_licence_terms
    type = params[:type]
    coll_id = params[:coll_id]

    if type == "collection"
      coll = Collection.find(coll_id)
      current_user.add_agreement_to_collection(coll, UserLicenceAgreement::READ_ACCESS_TYPE, type)
      name = coll.name
    else
      list = CollectionList.find(coll_id)
      current_user.add_agreement_to_collection(list, UserLicenceAgreement::READ_ACCESS_TYPE, type)
      name = list.name
    end

    current_user.accept_licence_request(coll_id)

    type == "collection" ? friendly_type = "collection" : friendly_type = "collection list"
    flash[:notice] = "Licence terms to #{friendly_type} #{name} accepted."
    redirect_to account_licence_agreements_path
  end

end
