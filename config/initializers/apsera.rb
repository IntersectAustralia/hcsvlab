Rails.application.config.aspera_temp_path = '/data/tmp'
Rails.application.config.aspera_source_dir = '/data'
Rails.application.config.aspera_nodeapi_config = YAML.load_file(Rails.root.join('config/aspera.yml'))[Rails.env.to_sym]
