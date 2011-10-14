class StubGameServer
  
  @servers = {}
  
  def self.name
    raise "Please define the name of #{to_s}" unless (match = /Stub(.*)Server/.match(to_s))
    match.captures[0].downcase
  end
  
  def self.inherited(subclass)
    raise "Overwriting an available class" if server_running? subclass.name
    @servers[subclass.name] = subclass.new
  end
  
  def self.server_running? name
    not @servers[name].nil?
  end
  
  def self.call_server name,message
    raise "Server \"#{name}\" not set! Choose from #{@servers.inspect}" unless server_running? name
    raise "Server can't be called!" unless @servers[name].respond_to? :take_message

    @servers[name].take_message(message)
  end
  
end

class Game
  alias_method :real_communicate_with_game_server, :communicate_with_game_server
  def stub_communicate_with_game_server message
    StubGameServer.call_server(self.name,message)
  end
  
  def communicate_with_game_server message
    begin
      real_communicate_with_game_server message
    rescue Errno::ECONNREFUSED => e
      result = stub_communicate_with_game_server message
    end
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
