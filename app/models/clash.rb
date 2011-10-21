require "redispusher.rb"

class Clash < ActiveRecord::Base
  belongs_to :game
  has_many :player_lists
  has_many :players, :through=>:player_lists
  
  validates :game_id, :presence=>true
  validates :name, :presence=>true
  validates :description, :presence=>true
  
  scope :forming, where(:status=>'forming')
  scope :playing, where(:status=>'playing')
  scope :complete, where(:status=>'complete')
  
  after_create :push_creation
  before_destroy :push_destruction
  
  def creating?
    self.status == 'creating'
  end
  
  def forming?
    self.status == 'forming'
  end
  
  def playing?
    self.status == 'playing'
  end
  
  def complete?
    self.status == 'complete'
  end

  def find_player_list list_name
    unless self.creating?
      PlayerList.where(:clash_id=>self.id,:name=>list_name).first
    else
      player_lists.each do |player_list|
        if player_list.name == list_name
          return player_list
        end
      end
      return nil
    end
  end

  def get_clash_info
    clash_info = {};

    clash_info[:public] = self.public_data
    clash_info[:private] = self.private_data

    return clash_info
  end

  def show_player_lists
    global_player_list = {};
    
    player_lists.each do |player_list|
      global_player_list[player_list[:name]] = []
      player_list.players.each do |player|
        global_player_list[player_list[:name]] << player.user.url
      end
    end
    
    return global_player_list
  end

  def all_player_search
    player_list_ids = PlayerList.where(:clash_id=>self.id).select(:id).all.map{|list|list.id}
    Player.where(:player_list_id=>player_list_ids)
  end
  
  def all_user_search
    user_ids = all_player_search.select(:user_id).all.map{|list|list.user_id}
    User.where(:id=>user_ids)
  end

  def player_search user
    all_player_search.where(:user_id=>user.id)
  end

  def find_player user
    player_search(user).first
  end  

  def joined? user
    player_search(user).any?
  end

  def startable?
    player_lists.each do |list|
      return false unless list.full?
    end
    return true
  end
  
  def get_url user
    raise Exceptions::ClashPlayError, "This game isn't currently playing" unless playing?
    raise Exceptions::ClashPlayError, "You must be logged in to play in a clash" if user.nil?
    
    player = find_player user
    raise Exceptions::ClashPlayError, "You're not a player for this clash" unless player
    
    #FIXME!, should return a custom URL for each player, so that the game site knows which player just came into the game
    return self.url
    
  end
  
  def start_forming user,form=nil
    raise Exceptions::ClashCreationError, "You must be logged in to create a clash" if user.nil?
    try_to_create(user,form) do |status,data|
      case status
      when 'game'
        #game creation successful, try to join the game before persisting the clash
        take_data data
        add_user user,data['start']
      when 'form'
        #need some more clash settings info to - fill out form before creation
        raise Exceptions::NeedCreateForm.new(data)
      when 'fail'  
          #this user cannot create this clash with the settings given
        raise Exceptions::ClashCreationError, data['error']
      end
    end
  end
  
  def add_user user,list,form=nil
    raise Exceptions::PlayerJoinError, "You Must be logged in to join" if user.nil?
    raise Exceptions::PlayerJoinError, "Which section are you trying to join" if list.nil?
    raise Exceptions::PlayerJoinError, "Can't join a clash unless it is still forming" unless forming? or creating?
    
    the_list = find_player_list list
    raise Exceptions::PlayerJoinError, "Can't find the requested section to join" unless the_list
    raise Exceptions::PlayerJoinError, "Sorry, but that section is currently full" if the_list.full?
    
    
    try_to_join(user,list,form) do |status,data|
      case status
      when 'join'
        old_player = find_player user
        @player = add_player user,list,data
        if old_player
          old_player.leave_clash
        end
      when 'form'
        raise Exceptions::NeedJoinForm.new(data)
      when 'fail'
        raise Exceptions::PlayerJoinError, data['error']
      end
    end
    
  end
  
  def remove_user user
    raise Exceptions::PlayerLeaveError, "You must be logged in to leave" if user.nil?
    player = find_player user
    
    raise Exceptions::PlayerLeaveError, "You were not part of this clash" if player.nil?
    player.leave_clash
  end
  
  def lost_player_notification
    unless self.players.any?
      if self.forming?
        self.destroy
      end
    end
  end
  
  def new_player_notification
    #not currently doing anything in response to new players
  end
  
  def start
    raise Exceptions::ClashStartError, "Can't start a clash unless it's currently forming" unless forming?
    
    try_to_start do |status,data|
      case status
      when 'start'  
        start_clash data['url']
        push_starting
      when 'fail'
        raise Exceptions::ClashStartError, data['error']
      end
    end
  end
  
  protected
  
  def try_to_create user,form
    message = {}

    if form
      message[:type] = :gameform
      message[:data] = JSON.generate(form)
    else
      message[:type] = :game
    end
    message[:user] = user.url
    
    response = self.game.send_message(message)
    raise Exceptions::ClashCreationError unless response
    yield response['status'],response['data']
  end

  def try_to_join user,list,form
    message = {}

    if form
      message[:type] = :joinform
      message[:data] = JSON.generate(form)
    else
      message[:type] = :join
    end
    message[:user] = user.url
    message[:clash] = get_clash_info
    
    response = self.game.send_message(message)
    raise Exceptions::PlayerJoinError unless response
    yield response['status'],response['data']
  end
  
  def try_to_start
    message = {}
    message[:type] = :start    
    message[:clash] = get_clash_info
    message[:players] = show_player_lists

    response = self.game.send_message(message)
    raise Exceptions::ClashStartError unless response
    yield response['status'],response['data']
  end

  def take_data data
    raise ArgumentError, "Clash Name required" unless data['name']
    raise ArgumentError, "Clash Description required" unless data['description']
    
    self.status = 'creating'
    self.name = data['name']
    self.description = data['description']
    self.public_data = data['publicdata'] if data['publicdata']
    self.private_data = data['privatedata'] if data['privatedata']
    for list in data['lists']
      new_player_list = PlayerList.new(:name=>list['name'],:player_count=>list['count'])
      self.player_lists << new_player_list
    end
  end
  
  def form
    self.status = 'forming'
    unless self.save
      logger.info "Unable to Form Clash :("
      raise Exceptions::ClashCreationError, "Unable to Form Clash"
    end
    
    self.player_lists.each do |list|
      unless list.save
        logger.info "List Creation Error"
        raise Exceptions::ClashCreationError, "Unable to Create PlayerList:#{list.name}"
      end
    end
  end
  
  
  def add_player user,list,player_data
    if creating?
      was_creating = true
      self.form
    else
      was_creating = false
    end
    
    raise Exceptions::PlayerJoinError, "Clash not currently forming" unless self.forming?
    
    the_list = find_player_list list
    
    raise Exceptions::PlayerJoinError, "Player List #{list} not found" if the_list.nil?
    
    player = Player.new(:player_list=>the_list,:user=>user)
    player.take_data player_data
    unless player.save
      logger.info "Unable to Save Player :("
      errorlist = []
      player.errors.each{|attr,msg| errorlist << msg }
      if was_creating
        self.destroy
        raise Exceptions::ClashCreationError, "Unable to join the Clash - #{errorlist.join(' - ')}"
      else
        raise Exceptions::PlayerJoinError, "Unable to join the Clash - #{errorlist.join(' - ')}"
      end
    end
    return player
  end
  
  def start_clash url
    raise Exceptions::ClashStartError, "Clash is not ready to start yet" unless startable?
    
    self.status = 'playing'
    self.url = url
    self.save
  end
  
  
  
  def push_creation
    RedisPusher.push_data("game#{self.game.id}",{:type=>"new_clash",:id=>self.id,:name=>self.name})
  end
  
  def push_destruction
    RedisPusher.push_data("game#{self.game.id}",{:type=>"clash_gone",:id=>self.id,:name=>self.name})
  end
  
  def push_starting
    RedisPusher.push_data("clash#{self.id}",{:type=>"clash_starting",:url=>self.url})
  end
end
