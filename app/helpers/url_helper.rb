module UrlHelper
  #
  # Retrieves the document relative url
  #
  def self::getDocumentUrl(doc)
    return "/catalog/#{doc.item.id}/document/#{doc.file_name.first}"
  end
end
