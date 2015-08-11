class NodeAPI

  attr_reader :hostname, :port, :user, :password, :verify_ssl

  def initialize(args={})
    @hostname = args[:hostname]
    @port = args[:port]
    @user = args[:user]
    @password = args[:password]
    @verify_ssl = args.fetch(:verify_ssl, true)
  end

  def info
    get('/info')
  end

  def space(request={})
    post('/space', request)
  end

  def browse(request={})
    post('/files/browse', request)
  end

  def search(request={})
    post('/files/search', request)
  end

  def create(request={})
    post('/files/create', request)
  end

  def rename(request={})
    post('/files/rename', request)
  end

  def delete(request={})
    post('/files/delete', request)
  end

  def upload_setup(request={})
    post('/files/upload_setup', request)
  end

  def download_setup(request={})
    post('/files/download_setup', request)
  end

  def transfers(method=:get, request={})
    case method
    when :get
      get('/transfers')
    when :post
      post('/transfers', request)
    end
  end

  def transfer(id, method=:get, request={})
    case method
    when :get
      get("/transfers/#{id}")
    when :put
      put("/transfers/#{id}", request)
    when :delete
      delete("/tranfers/#{id}")
    end
  end

  def locales(request={})
    get("/locales")
  end

  private

  def node_url(path)
    "https://#{user}:#{password}@#{hostname}:#{port}#{path}"
  end

  def get(path)
    json = RestClient::Request.execute(url: node_url(path), method: :get, verify_ssl: verify_ssl)
    JSON.parse(json) unless json.blank?
  end

  def post(path, payload)
    json = RestClient::Request.execute(url: node_url(path), method: :post, payload: payload.to_json, verify_ssl: verify_ssl)
    JSON.parse(json) unless json.blank?
  end

  def put(path, payload)
    json = RestClient::Request.execute(url: node_url(path), method: :put, payload: payload.to_json, verify_ssl: verify_ssl)
    JSON.parse(json) unless json.blank?
  end

  def delete(path)
    json = RestClient::Request.execute(url: node_url(path), method: :delete, verify_ssl: verify_ssl)
    JSON.parse(json) unless json.blank?
  end
end
