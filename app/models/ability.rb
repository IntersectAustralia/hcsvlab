class Ability
  include CanCan::Ability

  include Hydra::Ability
  # include Hydra::PolicyAwareAbility

  require 'blacklight/catalog'

  def initialize(user)

    # From Hydra::Ability.initialize
    @current_user = user || User.new # guest user (not logged in)
    @user = @current_user # just in case someone was using this in an override. Just don't.
    @session = session
    @cache = Hydra::PermissionsCache.new
    hydra_default_permissions

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

    alias_action :aspera_transfer_spec, :to => :read

    return if user.nil? || ! defined?(user.role)
    #return unless user.role

    ############################################################
    ##          PERMISSIONS OVER USERS                        ##
    ############################################################

    is_superuser = user.is_superuser?
    is_data_owner = user.is_data_owner?
    is_researcher = user.is_researcher?
    user_id = user.id

    if is_superuser
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

    if is_superuser
      can :manage, Blacklight::Catalog
      can :manage, Licence
      can :manage, AdminController
    elsif is_data_owner
      can :manage, Licence
      can :manage, AdminController
    elsif is_researcher
      can :read, Blacklight::Catalog
      cannot :manage, Licence
    end

    ############################################################
    ##          PERMISSIONS OVER ITEM LIST                    ##
    ############################################################

    can :manage, ItemList, :user_id => user_id
    can :read, ItemList, shared: true
    can :frequency_search, ItemList, shared: true
    can :concordance_search, ItemList, shared: true

    ############################################################
    ##          PERMISSIONS OVER COLLECTIONS                  ##
    ############################################################
    can :add_licence_to_collection, Collection, owner_id: user_id

    can :change_collection_privacy, Collection, owner_id: user_id

    can :revoke_access, Collection, owner_id: user_id

    can :delete_item_via_web_app, Collection, owner_id: user_id

    can :delete_document_via_web_app, Collection, owner_id: user_id

    can :web_add_item, Collection, owner_id: user_id

    can :web_add_document, Collection, owner_id: user_id

    # User can discover a collection only if he/she is the owner or if he/she was granted
    # with discover, read or edit access to that collection
    can :discover, Collection
    # User can read a collection only if he/she is the owner or if he/she was granted
    # with read or edit access to that collection
    can :read, Collection

    # User can edit a collection only if he/she is the owner or if he/she was granted
    # with edit access to that collection
    #can :edit, Collection do |aCollection|
    #  (user.id.eql? aCollection.owner_id) or
    #      ((user.groups & aCollection.edit_groups).length > 0)
    #end

    if is_data_owner or is_superuser
      can :create, Collection
      can :web_create_collection, Collection
    else
      cannot :create, Collection
    end

    ############################################################
    ##          PERMISSIONS OVER COLLECTION LIST              ##
    ############################################################

    if is_data_owner
      can :add_licence_to_collection, CollectionList, :owner_id => user_id
      can :approve_request, UserLicenceRequest, :user_id => user_id
      can :reject_request, UserLicenceRequest, :user_id => user_id
      can :change_collection_list_privacy, CollectionList, :owner_id => user_id
      can :revoke_access, CollectionList, :owner_id => user_id
    end

    ############################################################
    ##          PERMISSIONS OVER DOCUMENT AUDITS              ##
    ############################################################
    if is_data_owner or is_superuser
      can :read, DocumentAudit
    end
  end

end
