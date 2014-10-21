class Notifier < ActionMailer::Base

  PREFIX = "#{PROJECT_NAME} - "

  def notify_user_of_approved_request(recipient)
    @user = recipient
    mail( :to => @user.email,
          :from => APP_CONFIG['account_request_user_status_email_sender'],
          :reply_to => APP_CONFIG['account_request_user_status_email_sender'],
          :subject => PREFIX + "Your access request has been approved")
  end

  def notify_user_of_rejected_request(recipient)
    @user = recipient
    mail( :to => @user.email,
          :from => APP_CONFIG['account_request_user_status_email_sender'],
          :reply_to => APP_CONFIG['account_request_user_status_email_sender'],
          :subject => PREFIX + "Your access request has been rejected")
  end

  def notify_superusers_of_access_request(applicant)
    superusers_emails = User.get_superuser_emails
    @user = applicant
    mail( :to => superusers_emails,
          :from => APP_CONFIG['account_request_admin_notification_sender'],
          :reply_to => @user.email,
          :subject => PREFIX + "There has been a new access request")
  end

  def notify_superusers_of_issue(issue_report)
    superusers_emails = User.get_superuser_emails
    @issue_report = issue_report
    mail( :to => superusers_emails,
          :from => APP_CONFIG['account_request_admin_notification_sender'],
          :reply_to => @issue_report.user_email,
          :subject => PREFIX + "An issue has been reported")
  end

    # notifications for super users
  def notify_data_owner_of_user_licence_request(user_licence_request)
    @request = user_licence_request
    @coll = @request.request
    owner_email = @request.owner.email
    mail( :to => owner_email,
          :from => APP_CONFIG['licence_access_request_notification_sender'],
          :reply_to => @request.user_email,
          :subject => PREFIX + "There has been a new licence access request for a collection")
  end

  def notify_user_of_approved_collection_request(recipient, collection)
    @user = recipient
    @collection = collection
    mail( :to => @user.email,
          :from => APP_CONFIG['licence_access_request_response_sender'],
          :reply_to => APP_CONFIG['licence_access_request_response_sender'],
          :subject => PREFIX + "Your access request has been approved")
  end

  def notify_user_of_rejected_collection_request(recipient, collection, reason)
    @user = recipient
    @collection = collection
    @reason = reason
    mail( :to => @user.email,
          :from => APP_CONFIG['licence_access_request_response_sender'],
          :reply_to => APP_CONFIG['licence_access_request_response_sender'],
          :subject => PREFIX + "Your access request has been rejected")
  end

  def notify_user_that_they_cant_reset_their_password(user)
    @user = user
    mail( :to => @user.email,
          :from => APP_CONFIG['licence_access_request_response_sender'],
          :reply_to => APP_CONFIG['licence_access_request_response_sender'],
          :subject => PREFIX + "Reset password instructions")
  end

  def notify_aaf_user_approval_and_password(user, password)
    @user = user
    @password = password
    mail( :to => @user.email,
          :from => APP_CONFIG['account_request_user_status_email_sender'],
          :reply_to => APP_CONFIG['account_request_user_status_email_sender'],
          :subject => PREFIX + "Your access request has been approved")
  end

  def notify_user_that_reset_password_was_requested(email)
    @email = email
    mail( :to => email,
          :from => APP_CONFIG['account_request_user_status_email_sender'],
          :reply_to => APP_CONFIG['account_request_user_status_email_sender'],
          :subject => PREFIX + "Reset Password Request")
  end

  # send password reset instructions
  def reset_password_instructions(user)
    @user = user
    mail(:to => @user.email,
         :from => APP_CONFIG['account_request_user_status_email_sender'],
         :reply_to => APP_CONFIG['account_request_user_status_email_sender'],
         :subject => "#{PREFIX}Reset password instructions",
         :tag => 'password-reset',
         :content_type => "text/html")
  end

end
