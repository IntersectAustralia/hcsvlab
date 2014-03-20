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

    return if user.nil? || ! defined?(user.role)
    #return unless user.role

    ############################################################
    ##          PERMISSIONS OVER USERS                        ##
    ############################################################

    superuser = user.is_superuser?
    if superuser
      can :read, User
      can :update_role, User
      can :activate_deactivate, User
      can :admin, User
      can :reject, User
      can :approve, User
    end
    can :accept_licence_terms, User
    can :send_licence_request, User

    ############################################################
    ##          PERMISSIONS OVER BLACKLIGHT CATALOG           ##
    ############################################################

    if user.is_superuser?
      can :manage, Blacklight::Catalog
      can :manage, Licence
      can :manage, AdminController
    elsif user.is_data_owner?
      can :manage, Licence
      can :manage, AdminController
    elsif user.is_researcher?
      can :read, Blacklight::Catalog
      cannot :manage, Licence
    end


    ############################################################
    ##          PERMISSIONS OVER ITEM LIST                    ##
    ############################################################

    can :manage, ItemList, :user_id => user.id
    can :read, ItemList do |itemList|
      itemList.shared?
    end
    can :frequency_search, ItemList do |itemList|
      itemList.shared?
    end
    can :concordance_search, ItemList do |itemList|
      itemList.shared?
    end

    ############################################################
    ##          PERMISSIONS OVER COLLECTIONS                  ##
    ############################################################
    can :add_licence_to_collection, Collection do |aCollection|
      (user.email.eql? aCollection.flat_ownerEmail)
    end

    can :change_collection_privacy, Collection do |aCollection|
      (user.email.eql? aCollection.flat_ownerEmail)
    end

    can :revoke_access, Collection do |aCollection|
      (user.email.eql? aCollection.flat_ownerEmail)
    end

    # User can discover a collection only if he/she is the owner or if he/she was granted
    # with discover, read or edit access to that collection
    can :discover, Collection do |aCollection|
      #(user.email.eql? aCollection.flat_ownerEmail) or
      #    ((user.groups & aCollection.discover_groups).length > 0) or
      #    ((user.groups & aCollection.read_groups).length > 0) or
      #    ((user.groups & aCollection.edit_groups).length > 0)
      true
    end
    # User can read a collection only if he/she is the owner or if he/she was granted
    # with read or edit access to that collection
    can :read, Collection do |aCollection|
      #(user.email.eql? aCollection.flat_ownerEmail) or
      #    ((user.groups & aCollection.read_groups).length > 0) or
      #    ((user.groups & aCollection.edit_groups).length > 0)
      true
    end

    # User can edit a collection only if he/she is the owner or if he/she was granted
    # with edit access to that collection
    #can :edit, Collection do |aCollection|
    #  (user.email.eql? aCollection.flat_ownerEmail) or
    #      ((user.groups & aCollection.edit_groups).length > 0)
    #end

    ############################################################
    ##          PERMISSIONS OVER COLLECTION LIST              ##
    ############################################################

    if user.is_data_owner?
      can :add_licence_to_collection, CollectionList, :ownerId => user.id
      can :approve_request, UserLicenceRequest, :owner_email => user.email
      can :reject_request, UserLicenceRequest, :owner_email => user.email
      can :change_collection_list_privacy, CollectionList, :owner_email => user.email
      can :revoke_access, CollectionList, :owner_email => user.email
    end
  end

  ############################################################
  ##       GENERIC METHODS FOR ACTIVE_FEDORA OBJECTS        ##
  ############################################################

  def read_groups(pid)
    obj = ActiveFedora::Base.load_instance_from_solr(pid)
    obj.read_groups.concat(obj.edit_groups)
  end

  def edit_groups(pid)
    obj = ActiveFedora::Base.load_instance_from_solr(pid)
    obj.edit_groups
  end

  def read_persons(pid)
    obj = ActiveFedora::Base.load_instance_from_solr(pid)
    obj.read_users.concat(obj.edit_users)
  end

  def edit_persons(pid)
    obj = ActiveFedora::Base.load_instance_from_solr(pid)
    obj.edit_users
  end

end
