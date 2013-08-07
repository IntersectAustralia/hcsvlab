def populate_data
  load_password

  User.delete_all

  create_test_users
end

def create_test_users
  create_user(:email => "marc@intersect.org.au", :first_name => "Marc", :last_name => "Ziani de F")
  create_user(:email => "chrisk@intersect.org.au", :first_name => "Chris", :last_name => "Kenward")
  create_user(:email => "jared@intersect.org.au", :first_name => "Jared", :last_name => "Berghold")
  create_user(:email => "davidc@intersect.org.au", :first_name => "David", :last_name => "Clarke")
  create_user(:email => "matthew@intersect.org.au", :first_name => "Matt", :last_name => "Hillman")
  create_user(:email => "gabriel@intersect.org.au", :first_name => "Gabriel", :last_name => "Gasser Noblia")
  create_unapproved_user(:email => "unapproved1@intersect.org.au", :first_name => "Unapproved", :last_name => "One")
  create_unapproved_user(:email => "unapproved2@intersect.org.au", :first_name => "Unapproved", :last_name => "Two")
  set_role("marc@intersect.org.au", Role::SUPERUSER_ROLE)
  set_role("chrisk@intersect.org.au", Role::SUPERUSER_ROLE)
  set_role("jared@intersect.org.au", Role::SUPERUSER_ROLE)
  set_role("davidc@intersect.org.au", Role::SUPERUSER_ROLE)
  set_role("matthew@intersect.org.au", Role::SUPERUSER_ROLE)
  set_role("gabriel@intersect.org.au", Role::SUPERUSER_ROLE)
end

def set_role(email, role)
  user = User.where(:email => email).first
  role = Role.where(:name => role).first
  user.role = role
  user.save!
end

def create_user(attrs)
  u = User.new(attrs.merge(:password => @password))
  u.activate
  u.save!
end

def create_unapproved_user(attrs)
  u = User.create!(attrs.merge(:password => @password))
  u.save!
end

def load_password
  password_file = File.expand_path("#{Rails.root}/tmp/env_config/sample_password.yml", __FILE__)
  if File.exists? password_file
    puts "Using sample user password from #{password_file}"
    password = YAML::load_file(password_file)
    @password = password[:password]
    return
  end

  if Rails.env.development?
    puts "#{password_file} missing.\n" + 
    "Set sample user password:"
    input = STDIN.gets.chomp
    buffer = Hash[:password => input]
    Dir.mkdir("#{Rails.root}/tmp", 0755) unless Dir.exists?("#{Rails.root}/tmp")
    Dir.mkdir("#{Rails.root}/tmp/env_config", 0755) unless Dir.exists?("#{Rails.root}/tmp/env_config")
    File.open(password_file, 'w') do |out|
      YAML::dump(buffer, out)
    end
    @password = input
  else
    raise "No sample password file provided, and it is required for any environment that isn't development\n" +
    "Use capistrano's deploy:populate task to generate one"
  end

end

