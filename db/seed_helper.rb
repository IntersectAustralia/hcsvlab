def create_roles_and_permissions
  Role.delete_all
  Role.create!(:name => Role::SUPERUSER_ROLE)
  Role.create!(:name => Role::RESEARCHER_ROLE)
  Role.create!(:name => Role::DATA_OWNER_ROLE)
end

# Populates the languages table with the language names and codes from the languages CSV file
def populate_languages
  csv_file = File.join('lib', 'resources', 'languages-2015-11-09.csv')
  CSV.foreach(csv_file, :headers => true) do |csv_obj|
    unless Language.exists?(code: csv_obj['Code'], name: csv_obj['Name'])
      Language.create!(:code => csv_obj['Code'], :name => csv_obj['Name'])
    end
  end
end
