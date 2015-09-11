class Document < ActiveRecord::Base

  belongs_to :item
  has_many :document_audits, dependent: :destroy

end