class Hub < Sinatra::Base
  include UUIDTools
  use Rack::MethodOverride
  
  # settings
  set :version, "0.1"
  
  def initialize
    @db = Mongo::Connection.new.db("badges")
    super
  end
  
  # routes
  get '/' do; "Hub #{settings.version}"; end
  
  # register a new issuer
  post '/issuer/register' do
    path_to_identity = params['identity']
    secret_phrase = encrypt(params['phrase'])
    contents = JSON.parse(Typhoeus::Request.get(path_to_identity).body)
    host = URI(path_to_identity).host
    
    # bail if the secret phrase doesn't match
    unless contents['secret'] == secret_phrase
      headers = {'Content-Type' => 'text/plain'}
      body = {:error => "phrase_mismatch", "reason" => "The phrase submitted does not match the identity file."}.to_json
      return [403, headers, body]
    end
    
    # store that sucker in the database
    issuers = @db['issuers']
    
    # we shouldn't allow more than one entry per host
    if issuers.find(:host => host).entries.length > 0
      headers = {'Content-Type' => 'text/plain'}
      body = {:error => "exists", "reason" => "This issuer is already registered"}.to_json
      return [412, headers, body]
    end
    
    doc = {:host => host, :name => contents['name'], :secret => contents['secret']}
    res = issuers.insert(doc)
    res.inspect
  end
  
  get '/db-test' do
    issuers = @db['issuers']
    UUID.random_create.to_s
  end
  
  
  protected
  def encrypt phrase
    Digest::SHA2.new(256).update(phrase).to_s
  end
end

