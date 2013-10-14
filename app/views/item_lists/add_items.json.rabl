if params[:error].present?
  node(:error) { params[:error] }
else
  node(:success) { "#{@added_set.count} items added to #{@item_list.name}" }
end