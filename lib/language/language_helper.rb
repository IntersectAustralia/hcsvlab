module LanguageHelper

  public

  #
  # Returns a hash mapping language codes to their full name
  #
  def self::language_codes
    languages = {}
    csv_file = File.join('lib', 'language', 'languages-2015-11-09.csv')
    CSV.foreach(csv_file, :headers => true) do |csv_obj|
      languages[csv_obj['Code']] = csv_obj['Name']
    end
    languages
  end

  private

end