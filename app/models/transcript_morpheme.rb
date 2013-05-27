class TranscriptMorpheme < ActiveRecord::Base

  has_no_table

  attr_accessor :transcript_word_id, :position, :morpheme, :gloss

  belongs_to :word, class_name: 'TranscriptWord', foreign_key: :transcript_word_id

  default_scope order(:position)

  validates :position, presence: true, numericality: true

end
