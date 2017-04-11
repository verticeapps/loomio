class Clients::Base
  attr_reader :key

  def initialize(key: nil, secret: nil, token: nil)
    @key    = key
    @secret = secret
    @token  = token
  end

  def get(path, params = {}, success = default_callback, failure = default_callback)
    perform(:get, path, { query: default_params.merge(params) }, success, failure)
  end

  def post(path, params = {}, success = default_callback, failure = default_callback)
    perform(:post, path, { body: default_params.merge(params) }, success, failure)
  end

  def scope
    ""
  end

  private

  def perform(method, path, params, success, failure)
    response = JSON.parse HTTParty.send(method, [params.delete(:host) || host, path].join('/'), params.merge(headers: { 'Content-Type' => 'application/json; charset=utf-8' })).body
    if is_success?(response) then success else failure end.call(response)
  end

  # override for specific API failure behaviour
  def is_success?
    true
  end

  def default_callback
    ->(response) { response }
  end

  def default_params
    { client_id: @key, client_secret: @secret, token_name => @token }.delete_if { |k,v| v.nil? }
  end

  def token_name
    :token
  end

  def post_content(event, identifier)
    raise NotImplementedError.new
  end

  def serialized_event(event)
    begin
      "#{self.class.name.demodulize}::#{event.kind.classify}Serializer".constantize
    rescue NameError
      "#{self.class.name.demodulize}::BaseSerializer".constantize
    end.new(event, root: false).as_json
  end

  def host
    raise NotImplementedError.new
  end
end