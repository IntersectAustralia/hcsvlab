class Notifier < ActionMailer::Base

  PREFIX = "HCSVLAB - "

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

  # notifications for super users
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
          :from => APP_CONFIG['issue_report_admin_notification_sender'],
          :reply_to => @issue_report.user_email,
          :subject => PREFIX + "An issue has been reported")
  end

  def notify_data_owners_of_license_request(applicant, owner, collection)
    mail( :to => owner,
          :from => APP_CONFIG['license_access_request_admin_notification_sender'],
          :reply_to => applicant,
          :subject => PREFIX + "There has been a new license acceptance request")
  end

  def notify_user_that_they_cant_reset_their_password(user)
    @user = user
    mail( :to => @user.email,
          :from => APP_CONFIG['password_reset_email_sender'],
          :reply_to => APP_CONFIG['password_reset_email_sender'],
          :subject => PREFIX + "Reset password instructions")
  end

end
