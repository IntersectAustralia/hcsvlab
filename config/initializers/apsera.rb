# this directory is relative to the aspera document root of the transfer user
# e.g. document root is /home/[User]/ then aspera temp dir is /home/[User]/data/tmp
Rails.application.config.aspera_temp_dir = '/data/tmp'

Rails.application.config.aspera_nodeapi_config = YAML.load_file(Rails.root.join('config/aspera.yml'))[Rails.env.to_sym]
