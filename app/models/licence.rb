class Licence < ActiveRecord::Base

  attr_accessible :name, :owner_id, :text, :private
  belongs_to :owner, class_name: 'User'
  scope :public, where(private:false)

  # Validations
  validates_presence_of :name, message: 'Licence Name can not be blank'
  validates_length_of :name, maximum: 255, message:'Name is too long (maximum is 255 characters)'
  validates_presence_of :text, message: 'Licence Text can not be blank'

  validates_uniqueness_of :name, scope: :owner_id, message: "Licence name '%{value}' already exists"
  # Potential Rails 4 validation
  # validates_uniqueness_of :name, message: "Licence name '%{value}' already exists", conditions: -> { where(private: false) }
  validate :duplicate_of_public_licence

  def duplicate_of_public_licence
    if Licence.public.where(name: self.name).exists?
      errors[:base] << "Licence name '#{self.name}' already exists"
    end
  end

end
