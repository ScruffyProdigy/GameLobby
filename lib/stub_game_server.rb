require 'net/http'
require 'rspec/mocks/methods'

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
  
  def self.set_server url,server
    @servers[url.to_s] = server
  end
  
  def initialize url
    StubGameServer.set_server url,self
    Net::HTTP.stub!(:post_form).and_return do |url, message|
      StubGameServer.call_server url.to_s,message
    end
  end
  
  def self.server_running? url
    not @servers[url.to_s].nil?
  end
  
  def self.call_server url,message
    raise "Server at URL:\"#{url}\" not set! Choose from #{@servers.inspect}" unless server_running? url
    raise "Server can't be called!" unless @servers[url].respond_to? :take_message

    response = @servers[url].take_message( message )
    res = FakeHTTPResponse.new(response)
  end
end

class StubChessServer < StubGameServer

  def take_message message
#    body = Rack::Utils.parse_query message
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
      {'status'=>'start','data'=>{'url'=>'http://127.0.0.1:8125/game'}}
    end
  end
end

class StubRoshamboServer < StubGameServer
  def take_message message
#    body = Rack::Utils.parse_query message
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
      {'status'=>'start','data'=>{'url'=>'http://127.0.0.1:8125/game'}}
    end
  end
end