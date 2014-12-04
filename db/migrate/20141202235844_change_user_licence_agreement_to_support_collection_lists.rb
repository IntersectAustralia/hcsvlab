class ChangeUserLicenceAgreementToSupportCollectionLists < ActiveRecord::Migration
  def up
    add_column :user_licence_agreements, :name, :string
    add_column :user_licence_agreements, :access_type, :string
    add_column :user_licence_agreements, :collection_type, :string


    CollectionList.all.each do |col_list|
      existing_users = []
      col_list.collections.each do |col|
        ulas = UserLicenceAgreement.where("group_name LIKE '#{col.name}%'")
        existing_users += ulas.pluck(:user_id)
        ulas.delete_all
      end

      unless existing_users.empty?
        existing_users.uniq.each do |uid|
          new_ula = UserLicenceAgreement.new
          new_ula.user_id = uid
          new_ula.licence_id = col_list.licence_id
          new_ula.name = col_list.name
          new_ula.access_type = 'read'
          new_ula.collection_type = 'collection_list'
          new_ula.save!
        end
      end
    end

    UserLicenceAgreement.all.each do |ula|
      unless ula.group_name.nil?
        group_name = ula.group_name.split('-')
        ula.name = group_name[0]
        ula.access_type = group_name[1]
        ula.collection_type = 'collection'
        ula.save!
      end
    end

    remove_column :user_licence_agreements, :group_name
  end

  def down
    remove_column :user_licence_agreements, :handle
    remove_column :user_licence_agreements, :access_type
    remove_column :user_licence_agreements, :collection_type

    add_column :user_licence_agreements, :group_name, :string
  end
end
