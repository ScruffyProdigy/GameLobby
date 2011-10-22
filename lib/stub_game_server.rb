require 'net/http'
require 'rspec/mocks/methods'

def url_string url
  
end

class FakeHTTPResponse
  @body
  def initialize body
    @body = JSON.generate body
  end
  
  def class
    Net::HTTPSuccess
  end
  
  def body
    @body
  end
end

class StubGameServer
  
  @servers = {}
  @server_definitions = {}
  
  def self.name
    raise "Please define the name of #{to_s}" unless (match = /Stub(.*)Server/.match(to_s))
    match.captures[0].downcase
  end
  
  def self.get_server url
    url_string = "#{url.scheme}://#{url.host}"
    url_string += ":#{url.port}" if url.port
    @servers[url_string]
  end
  
  def self.set_server url,server
    if String === url
      url = URI.parse url
    end
    url_string = "#{url.scheme}://#{url.host}"
    url_string += ":#{url.port}" if url.port
    @servers[url_string] = server
  end
  
  def self.inherited subclass
    raise "Overwriting an available class" if server_defined? subclass.name
    @server_definitions[subclass.name] = subclass
  end

  def self.server_defined? name
    not @server_definitions[name].nil?
  end

  def self.create_server name,url
    @server_definitions[name].new url
  end
  
  
  def initialize url
    StubGameServer.set_server url,self
    @url = url
    Net::HTTP.stub!(:post_form).and_return do |url, message|
      StubGameServer.post_to_server url,message
    end
  end
  
  def self.server_running? url
    not get_server(url).nil?
  end
  
  def self.post_to_server url,message
    server = get_server(url)
    raise "Server at URL:\"#{url}\" not set! Choose from #{@servers.inspect}" if server.nil?
    raise "Server can't be called!" unless server.respond_to? :take_message
    
    response = server.take_message( url.path,url.query,message )
    res = FakeHTTPResponse.new(response)
  end
  
  def self.get_from_server url
    if String === url
      url = URI.parse url
    end
    server = get_server(url)
    raise "Server at URL:\"#{url}\" not set! Choose from #{@servers.inspect}" if server.nil?
    raise "Server can't be called!" unless server.respond_to? :take_message
    
    response = server.take_message( url.path,url.query)
  end
end

class StubChessServer < StubGameServer

  def take_message path,query,message
    case path
    when ''
      case message['type']
      when :game
        {'status'=>'form','data'=>{'gamename'=>{'label'=>'Game Name','type'=>'string'},'description'=>{'label'=>'Description','type'=>'string'}}};
      when :gameform
        data = JSON.parse(message['data']);
        result = {'status'=>'game','data'=>{'name'=>data['gamename'],'description'=>data['description'],'lists'=>[{'name'=>'white','count'=>1},{'name'=>'black','count'=>1}],'start'=>'white'}};
      when :join
        {'status'=>'join','data'=>{}}
      when :joinform
        {'status'=>'error','data'=>{'error'=>'you don\'t need a form'}}
      when :start
        {'status'=>'start','data'=>{'url'=>"#{@url}/game"}}
      end
    when '/game'
      
    end
  end
end

class StubRoshamboServer < StubGameServer
  def initialize url
    super
    @url = url
  end
  
  def take_message path,query,message=nil
    case path
    when ''
      case message['type']
      when :game
        {'status'=>'form','data'=>{'gamename'=>{'label'=>'Game Name','type'=>'string'},'description'=>{'label'=>'Description','type'=>'string'}}};
      when :gameform
        data = JSON.parse(message['data']);
        result = {'status'=>'game','data'=>{'name'=>data['gamename'],'description'=>data['description'],'lists'=>[{'name'=>'players','count'=>2}],'start'=>'players'}};
      when :join
        {'status'=>'join','data'=>{}}
      when :joinform
        {'status'=>'error','data'=>{'error'=>'you don\'t need a form'}}
      when :start
        {'status'=>'start','data'=>{'url'=>"#{@url}/game"}}
      end
    when '/game'
      "<html><head></head><body>Roshambo</body></html>"
    end
  end
end