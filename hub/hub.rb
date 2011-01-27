class Hub < Sinatra::Base
  include Log4r
  include UUIDTools
  use Rack::MethodOverride
  
  # settings
  set :version, "0.1"
  
  def initialize
    @db = Mongo::Connection.new.db("badges")
    @logger = Logger.new "hub"
    @logger.outputters = FileOutputter.new('hub', :filename => 'hub.log')
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
    
    # get the contents of the badge from the issuer
    badge_contents = JSON.parse(Typhoeus::Request.get(badge_uri).body)
    
    # merge in auxiliary data
    badge_contents.merge!({
      "_id" => generate_id,
      :uri => badge_uri,
      :issuer => issuer['host'],
      :org => issuer['name'],
      :last_update => Time.now.to_i
    })
    
    # put the badge in the collection
    badges_collection.insert(badge_contents)
    badge_contents.to_json
  end
  
  
  # get some badges for a user's backpack
  get '/badges' do
    badges_collection = @db['badges']
    user = env['HTTP_FROM']
    pass = env['HTTP_AUTHENTICATION']
    
    # pretend some validation goes on here
    
    get_user_badges(user).to_json
  end

  
  # remove all badges from the collection
  get '/badges/nuke' do
    res = @db['badges'].remove({})
    res.inspect
  end
  
  protected
  def get_user_badges email
    users_collection = @db['users']
    badges_collection = @db['badges']
    badgeset = nil
    matches = users_collection.find({:_id => email}).entries
    if matches.length == 0
      # create user and set all badges to private by default
      badges = badges_collection.find(:owner => email).entries
      doc = {
        "_id" => email,
        :badges => {
          :private => badges,
          :public => [],
          :rejected => [],
        },
      }
      users_collection.insert(doc)
      badgeset = doc[:badges]
    else
      badgeset = matches[0]['badges']
    end
    revalidate(badgeset)
  end
  
  def generate_id ; UUIDTools::UUID.random_create.to_s.delete('-'); end
  def encrypt phrase ; Digest::SHA2.new(256).update(phrase).to_s ; end
  def revalidate badgeset
    # TODO: this should really return the updated set
    badges = badgeset.values.flatten
    badges_collection = @db['badges']
    now = Time.now.to_i
    badges.each do |badge|
      next unless badge['expires'] and (now > badge['last_update'].to_i + badge['expires'].to_i)
      # TODO: this should make sure that the badge still exists before trying to parse
      # TODO: this should be done with hydra in parallel
      updated_contents = JSON.parse(Typhoeus::Request.get(badge['uri']).body)

      updated_badge = badge.merge(updated_contents)
      updated_badge['last_update'] = now
      badges_collection.update({"_id" => badge['_id']}, updated_badge)
    end
    return badgeset
  end
end

