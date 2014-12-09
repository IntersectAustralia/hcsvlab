class DocumentAudit < ActiveRecord::Base

  belongs_to :document
  belongs_to :user

  attr_accessible :document, :user

  def self.get_last_100(current_user)
    document_audits = DocumentAudit.includes(:user, :document => {:item => :collection}).limit(100).order('document_audits.created_at DESC')

    unless current_user.is_superuser?
      document_audits = document_audits.where(collections: {owner_id: current_user.id})
    end

    return document_audits
  end

  def self.get_csv(current_user)

    document_audits = DocumentAudit.includes(:user, :document => {:item => :collection})
    unless current_user.is_superuser?
      document_audits = document_audits.where(collections: {owner_id: current_user.id})
    end

    file = Tempfile.new("newfile")
    unless document_audits.empty?
      header = ['collection', 'item', 'document', 'user_name', 'user_email', 'time_downloaded']
      file.puts header.join(',')
      document_audits.each do |audit|
        values =  [audit.document.item.collection.name,
                 "#{audit.document.item.handle.gsub ':', '-'}",
                 "#{audit.document.item.handle.gsub ':', '/'}/#{audit.document.file_name}",
                 "#{audit.user.first_name} #{audit.user.last_name}",
                 audit.user.email,
                 "#{audit.created_at.localtime.strftime('%d/%m/%Y %H:%M')}"]
        file.puts values.join(",")
      end
    end
    file.close

    return file
  end
end
