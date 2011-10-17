class GamesController < ApplicationController
  before_filter :load_game, :except => [ :index, :new, :create ]
  before_filter :ensure_logged_in, :except => [ :index, :show ]
  before_filter :ensure_is_developer, :only => [ :edit, :update, :destroy ]
  
  respond_to :html, :xml, :json
  
  def index
    @games = Game.all
    respond_with @games
  end
  
  def show
    respond_with @game
  end
  
  def new
    @game = Game.new
    respond_with @game
  end
  
  def create
    @game = Game.new params[:game]
    if @game.save
      GameDeveloper.create :game => @game, :user=>current_user
      respond_with @game
    else
      render 'new'
    end
  end
  
  def edit
    respond_with @game
  end
  
  def update
    if @game.update_attributes params[:game]
      respond_with @game
    else
      render 'edit'
    end
  end
  
  def destroy
    @game.destroy
    respond_with @game, :location => games_path
  end
  
  protected
  def load_game
    @game = Game.find params[:id]
    
    render :status => 404 if @game.nil?
  end
  
  def ensure_logged_in
    redirect_to games_path unless logged_in?
  end
  
  def ensure_is_developer
    redirect_to games_path unless @game.is_developer? current_user
  end
  
end