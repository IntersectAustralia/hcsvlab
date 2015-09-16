object false
if params[:error].present?
  node(:error) { params[:error] }
else
  node(:success) { @success_message }
end