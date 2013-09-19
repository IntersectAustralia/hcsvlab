class HcsvlabActiveFedora < ActiveFedora::Base

  # Retrieve the Fedora object matching the supplied conditions
  # @param[Hash,String] conditions hash representing the query part of an solr statement.
  # This method will generate conditions based simple equality
  # combined using the boolean AND operator.
  #
  # The aim of this method is to reduce the amount of HTTP requests performed to retrieve a Fedora
  # object
  #
  # @param[Hash] options
  # @option opts [Array] :sort a list of fields to sort by
  # @option opts [Array] :rows number of rows to return
  def self.find_and_load_from_solr(conditions, opts={})
    classObject = Object.const_get(self.to_s)

    processedConditions = {}
    reflections = classObject.reflections
    conditions.each_pair do |key, value|
      if (reflections.has_key?(key))

        newKey = :"#{reflections[key].options[:property].to_s}_ssim"
        newValue = "info:fedora/#{value}"
        processedConditions[newKey] = newValue
      else
        processedConditions[key] = value
      end
    end

    found_documents = []
    docHash = Array(classObject.find_with_conditions(processedConditions, opts.merge({fl:"id"})))
    docHash.each do |aDocId|
      doc = classObject.load_instance_from_solr(aDocId["id"])
      found_documents << doc
    end

    found_documents
  end

end