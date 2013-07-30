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

    #take a screenshot. The use of 'localhost' addresses will cause imgkit to hang, so we bypass the process on localhost
    if (@issue_report.include_screenshot == '1' && !@issue_report.url.include?("http://localhost"))
      kit = IMGKit.new(@isssue_report.url, :quality => 50)
      file = kit.to_file('tmp/file.jpg')
      @issue_report.screenshot = file.path
    end

    if @issue_report.valid?
      Notifier.notify_superusers_of_issue(@issue_report).deliver
      redirect_to(root_path, :notice => "Issue was reported successfully." )
    else
      flash.now.alert = "The issue was not reported."
      render :new, {@issue_report => @issue_report}
    end

  end

end
