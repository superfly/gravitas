require 'sinatra'
require 'rbnacl/libsodium'
require 'rbnacl'
require 'base64'
require 'faraday'

default_key = ENV['GRAVITAS_KEY']
get '/:data' do
  key = request.env['HTTP_GRAVITAS_KEY']
  key = default_key if key.nil? || key == ""
  key = begin
          Base64.urlsafe_decode64(key)
        rescue
          halt(400, "Invalid key")
        end

  box = RbNaCl::SimpleBox.from_secret_key(key)

  data = params[:data]
  puts params.inspect
  data = begin
           Base64.urlsafe_decode64(data)
         rescue
           halt(404, "Not found: #{data}")
         end
  gravatar_path = box.decrypt(data)

  gravatar = "https://www.graatar.com/avatar#{gravatar_path}"
  logger.debug "GET: #{gravatar_path}"

  resp = begin
           Faraday.get(gravatar)
         rescue
           halt(500, "Error getting gravatar: #{$!.message}")
         end

  status response.status

  resp.headers.each do |k,v|
    if k == "content-disposition"
      v = v.gsub(/filename="(.*)\.([^\.]*)"/, 'filename="' + params[:data] + '.\2"')
    end

    if /[a-f0-9]{32}/.match(v)
      # this header leaks md5s
      logger.debug "(nuking leaky header) #{k}: #{v}"
      v = nil
    end

    response.headers[k] = v if v
  end

  response.write(resp.body)
end

post '/' do
end
