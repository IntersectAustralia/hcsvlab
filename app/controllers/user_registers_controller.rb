class UserRegistersController < Devise::RegistrationsController
  # based on https://github.com/plataformatec/devise/blob/v2.0.4/app/controllers/devise/registrations_controller.rb

  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy, :edit_password, :update_password, :profile, :licence_agreements, :index]

  def profile

  end

  # Override the create method in the RegistrationsController to add the notification hook
  def create
    build_resource

    if resource.save
      Notifier.notify_superusers_of_access_request(resource).deliver
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  # Override the update method in the RegistrationsController so that we don't require password on update
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    if resource.update_attributes(params[resource_name])
      if is_navigational_format?
        if resource.respond_to?(:pending_reconfirmation?) && resource.pending_reconfirmation?
          flash_key = :update_needs_confirmation
        end
        set_flash_message :notice, flash_key || :updated
      end
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  def edit_password
    respond_with resource
  end

  # Mostly the same as the devise 'update' method, just call a different method on the model
  def update_password
    if resource.update_password(params[resource_name])
      set_flash_message :notice, :password_updated if is_navigational_format?
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      render :edit_password
    end
  end

  def licence_agreements
  end

  def download_token
    if current_user.authentication_token.nil? #generate auth token if one doesn't already exist
      current_user.reset_authentication_token!
    end

    file = Tempfile.new("newfile")
    hash = {}
    hash[:apiKey] = current_user.authentication_token
    hash[:cacheDir] = "/path/to/directory"
    file.puts(hash.to_json)
    file.close
    send_file file.path, type: :json, :filename => "hcsvlab.config", :disposition => "attachment"
  end

  def generate_token
    current_user.reset_authentication_token!
    redirect_to :back, :notice => "Your new API token has been generated."
  end

  def delete_token
    current_user.authentication_token = nil
    current_user.save!
    redirect_to :back, :notice => "Your API token has been deleted."
  end

end
