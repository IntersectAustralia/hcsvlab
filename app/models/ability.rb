class Ability
  include CanCan::Ability

  include Hydra::Ability
  #include Hydra::PolicyAwareAbility

  require 'blacklight/catalog'

  def initialize(user)

    # From Hydra::Ability.initialize
    @current_user = user || User.new # guest user (not logged in)
    @user = @current_user # just in case someone was using this in an override. Just don't.
    @session = session
    @cache = Hydra::PermissionsCache.new
    hydra_default_permissions()
    
    # alias edit_role to update_role so that they don't have to be declared separately
    alias_action :edit_role, :to => :update_role
    alias_action :edit_approval, :to => :approve

    # alias activate and deactivate to "activate_deactivate" so its just a single permission
    alias_action :deactivate, :to => :activate_deactivate
    alias_action :activate, :to => :activate_deactivate

    # alias access_requests to view_access_requests so the permission name is more meaningful
    alias_action :access_requests, :to => :admin

    # alias reject_as_spam to reject so they are considered the same
    alias_action :reject_as_spam, :to => :reject

    return if user.nil? || ! defined? user.role
    #return unless user.role

    can :manage, ItemList, :user_id => user.id

    superuser = user.is_superuser?
    if superuser
      can :read, User
      can :update_role, User
      can :activate_deactivate, User
      can :admin, User
      can :reject, User
      can :approve, User
    end

    if user.is_superuser?
        can :manage, Blacklight::Catalog
    elsif user.is_researcher?
        can :read, Blacklight::Catalog
    end    
  end

end
