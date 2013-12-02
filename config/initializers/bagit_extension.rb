include BagIt

Bag.class_eval do

  # Add a bag file link
  def add_file_link(base_path, src_path=nil)
    path = File.join(data_dir, base_path)
    raise "Bag file exists: #{base_path}" if File.exist? path
    FileUtils::mkdir_p File.dirname(path)

    if src_path.nil?
      f = File.open(path, 'w') { |io| yield io }
    else
      f = FileUtils::symlink src_path, path
    end
    write_bag_info
    return f
  end

end
