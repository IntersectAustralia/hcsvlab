#https://gist.github.com/abriening/1255051
module ErrorResponseActions

  ERROR_RESPONSE_ACTIONS = %[authorization_error
                             resource_not_found
                             page_not_found
                             not_implmented
                             route_not_found
                             method_not_allowed].freeze

  def authorization_error(exception)
    # 403 Forbidden response
    respond_to do |format|
      format.html {
        flash[:alert] = exception.message
        redirect_to root_url
      }
      format.xml { render :xml => exception.message, :status => 403 }
      format.json { render :json => exception.message, :status => 403 }
    end
  end

  def resource_not_found(exception)
    respond_to do |format|
      format.html {
        flash[:alert] = exception.message
        redirect_to root_url
      }
      format.xml { render :xml => exception.message, :status => 404 }
      format.json { render :json => exception.message, :status => 404 }
    end
  end

end