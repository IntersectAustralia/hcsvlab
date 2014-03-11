module JsonCompare

  #
  # This class will compare to json objects without taking into account the order
  # of the objects in an array.
  #
  class OrderlessComparer < JsonCompare::Comparer
    def compare_arrays(old_array, new_array)
      old_array_length = old_array.count
      new_array_length = new_array.count
      inters = [old_array.count, new_array.count].min

      result = get_diffs_struct

      (0..inters).map do |n|
        element = old_array[n]

        occurrences_in_old_array = countOccurrences(element, old_array)
        occurrences_in_new_array = countOccurrences(element, new_array)

        if occurrences_in_old_array < occurrences_in_new_array
          result[:append] = element
        elsif occurrences_in_old_array > occurrences_in_new_array
          result[:remove] = element
        end

      end

      # the rest of the larger array
      if inters == old_array_length
        (inters..new_array_length-1).each do |n|
          result[:append][n] = new_array[n]
        end
      else
        (inters..old_array_length-1).each do |n|
          result[:remove][n] = old_array[n]
        end
      end

      filter_results(result)

    end

    private

    #
    #
    #
    def countOccurrences(element, old_array)
      count = 0
      old_array.each do |otherElement|
        res = compare_elements(element, otherElement)
        count = count + 1 if res.empty?
      end
      count
    end
  end
end
