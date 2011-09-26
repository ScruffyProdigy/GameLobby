class GamesController < ApplicationController
  before_filter :find_game, :only=>[:show,:edit,:update,:destroy]
  before_filter :ensure_logged_in, :except=>[:index,:show]
  before_filter :ensure_is_developer, :only=>[:edit,:update,:destroy]
  
  respond_to :html, :xml, :json
  
  def index
    respond_with(@games = Game.all)
  end
  
  def show
    respond_with @game
  end
  
  def new
    @game = Game.new
    respond_with @game
  end
  
  def create
    @game = Game.new(params[:game])
    if @game.save
      GameDeveloper.create({:game=>@game,:user=>current_user})
      respond_with @game
    else
      render "new"
    end
  end
  
  def edit
    respond_with @game
  end
  
  def update
    if @game.update_attributes(params[:game])
      respond_with @game
    else
      render "edit"
    end
  end
  
  def destroy
    @game.destroy
    respond_with @game, :location=>games_path
  end
  
  protected
  def find_game
    @game = Game.find(params[:id])
    if @game.nil?
      redirect_to games_path
    end
  end
  
  def ensure_logged_in
    redirect_to games_path unless logged_in?
  end
  
  def ensure_is_developer
    redirect_to games_path unless @game.is_developer? current_user
  end
  
end