def create_roles_and_permissions
  Role.delete_all

  #TODO: create your roles here
  superuser = "hcsvlab-admin"
  Role.create!(:name => superuser)
  Role.create!(:name => 'researcher')
end


