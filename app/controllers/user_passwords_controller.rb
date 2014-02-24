class UserPasswordsController < Devise::PasswordsController
  # based on https://github.com/plataformatec/devise/blob/v2.0.4/app/controllers/devise/passwords_controller.rb

  def create
    # Override the devise controller so we don't show errors (since we don't want to reveal if the email exists)
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    # the only error we show is the empty email one
    if params[resource_name][:email].empty?
      respond_with resource
    else

      user = User.find_all_by_email(params[resource_name][:email])

      if (user.empty?)
        flash[:error] = "Invalid email."
        redirect_to new_user_password_path and return
      end

      set_flash_message(:notice, :send_paranoid_instructions) if is_navigational_format?
      redirect_to(new_user_session_path)
    end
  end

end
