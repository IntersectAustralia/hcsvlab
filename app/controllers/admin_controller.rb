class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorize_admin

  def index
  end

  def document_audit
    @document_audits = DocumentAudit.get_last_100(current_user)
  end

  def document_audit_download
    send_file DocumentAudit.get_csv(current_user).path, :filename => "document_audit.csv", :disposition => "attachment"
  end

  private

  def authorize_admin
    authorize! :manage, AdminController
  end

end
