def create_roles_and_permissions
  Role.delete_all
  Role.create!(:name => Role::SUPERUSER_ROLE)
  Role.create!(:name => Role::RESEARCHER_ROLE)
end


