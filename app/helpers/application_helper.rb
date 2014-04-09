module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  # convenience method to render a field on a view screen - saves repeating the div/span etc each time
  def render_field(label, value)
    render_field_content(label, (h value))
  end

  def render_field_table(label, value)
    render_field_table_content(label, (h value))
  end

  def render_field_if_not_empty(label, value)
    render_field_content(label, (h value)) if value != nil && !value.empty?
  end

  # as above but takes a block for the field value
  def render_field_with_block(label, &block)
    content = with_output_buffer(&block)
    render_field_content(label, content)
  end

  def render_field_table_with_block(label, &block)
    content = with_output_buffer(&block)
    render_field_table_content(label, content)
  end

  def user_dropdown_menu
    "#{h current_user.full_name}<b class=\"caret\"></b>".html_safe
  end  

  # helper class for tabs, adds 'active' class when on the input path
  def activepath?(test_path)
    return 'active' if (request.path == test_path and !current_user.nil?)
  end

  # helper class for tabs, adds 'active' class when on the input path
  def activepath_with_loggued_user?(test_path)
    Array(test_path).each do |path|
      return 'active' if request.path == path
    end
  end

  def activepath_fuzzy?(test_path)
    isActive = false
    Array(test_path).each do |param|
      isActive = isActive || request.path.include?(param)
    end

    return 'active' if isActive
  end

  private
  def render_field_content(label, content)
    div_class = cycle("field_bg","field_nobg")
    div_id = label.tr(" ,", "_").downcase
    html = "<div class='#{div_class} inlineblock' id='display_#{div_id}'>"
    html << '<span class="label_view">'
    html << (h label)
    html << ":"
    html << '</span>'
    html << '<span class="field_value">'
    html << content
    html << '</span>'
    html << '</div>'
    html.html_safe
  end

  def render_field_table_content(label, content)
    div_class = cycle("field_bg","field_nobg")
    div_id = label.tr(" ,", "_").downcase
    html = "<tr class='#{div_class} inlineblock' id='display_#{div_id}'>"
    html << '<td class="label_view">'
    html << (h label)
    html << '</td>'
    html << '<td class="field_value">'
    html << content
    html << '</td>'
    html << '</tr>'
    html.html_safe
  end

  def render_frequency_search_items(num, den, zero_dp = true)
    if num == "###"
      return num
    end

    num = num.to_i
    den = den.to_i

    if den == 0
      result = '0 / 0'
    elsif zero_dp
      result = sprintf('%d / %d (%3d%%)', num, den, (num*100)/den)
    else
      result = sprintf('%d / %d (%6.3f%%)', num, den, (num*100.0)/den)
    end
    return result
  end
end
