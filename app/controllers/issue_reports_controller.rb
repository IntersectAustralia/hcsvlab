class IssueReportsController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource

  def new
    @issue_report ||= IssueReport.new
    @issue_report.url ||= params[:url]
  end

  def create
    @issue_report = IssueReport.new(params[:issue_report])
    @issue_report.user_email = current_user.email
    @issue_report.timestamp = Time.now

    if @issue_report.valid?
      Notifier.notify_superusers_of_issue(@issue_report).deliver
      redirect_to(root_path, :notice => "Issue was reported successfully."  )
    else
      render :new, {@issue_report => @issue_report}
    end

  end

end