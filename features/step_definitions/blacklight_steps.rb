When /^I toggle the select all checkbox$/ do
  find('#allnonecheckbox').click
end

When /^I expand the facet (.*)$/ do |name|
  facetMenu = find(:xpath, "//h5[@class='twiddle']", :text => name, visible: false)
  facetMenu.click
end