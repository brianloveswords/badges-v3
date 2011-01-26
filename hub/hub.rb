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
  
  # store a badge for an issuer
  post '/issuer/store' do
    issuers_collection = @db['issuers']
    badges_collection = @db['badges']
    
    badge_uri = params['badge']
    host = URI(badge_uri).host
    secret_phrase = encrypt(params['phrase'])
    
    # make sure the issuer exists and passphrase is correct
    issuer_query = issuers_collection.find(:host => host, :secret => secret_phrase).entries
    if issuer_query.length == 0
      headers = {'Content-Type' => 'text/plain'}
      body = {:error => "issuer_not_found", "reason" => "Either the issuer could not be found or the passphrase is incorrect"}.to_json
      return [403, headers, body]
    end
    
    issuer = issuer_query[0]
    # make sure the badge doesn't already exist
    badge_query = badges_collection.find(:uri => badge_uri).entries
    if badge_query.length > 0
      headers = {'Content-Type' => 'text/plain'}
      body = {:error => "badge_exists", "reason" => "This badge already exists in the system. Badge URIs must be unique."}.to_json
      return [403, headers, body]
    end
    
    badge_contents = JSON.parse(Typhoeus::Request.get(badge_uri).body)
    badge_contents['uuid'] = generate_id
    badge_contents['uri'] = badge_uri
    badge_contents['issuer'] = issuer['host']
    badge_contents['org'] = issuer['name']
    
    badges_collection.insert(badge_contents)
    badge_contents.to_json
  end
  
  protected
  def generate_id ; UUIDTools::UUID.random_create.to_s; end
  def encrypt phrase ; Digest::SHA2.new(256).update(phrase).to_s ; end
end

