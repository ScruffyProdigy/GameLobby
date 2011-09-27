class ClashesController < ApplicationController
  before_filter :find_clash, :only=>[:show,:edit,:update,:destroy]
  
  respond_to :html, :xml, :json
  
  def new
  end
  
  def show
    respond_with @clash
  end
  
  def create
    begin
      @clash = Clash.new(params[:clash])
      form_info = params[:form] or nil
      @clash.start_forming current_user,form_info
      
    rescue ClashCreationError
      #should flash error info
      respond_with @clash.game
      
    rescue PlayerJoinError
      #should flash error info
      respond_with @clash.game
      
    rescue NeedCreateForm=>error
      #need form filled out to continue
      @form = error.form
      render :new
      
    else
      respond_with @clash
    end
  end
  
  def update
    case params[:clash][:action]
    when 'joining'
      begin
        form_info = params[:form] or nil
        @clash.add_user current_user,params[:clash][:list],form_info
      rescue PlayerJoinError => error
        #should flash error info
        flash[:error] = error.to_s
        respond_with @clash
      rescue NeedJoinForm => error
        #need form filled out to continue
        @form = error.form
        respond_with @clash
      rescue PlayerLeaveError
        #player was trying to move to a different spot, but failed to leave the current one
        #should flash error info
      else
        respond_with @clash
      end
    when 'leaving'
      begin
        @game = @clash.game
        @clash.remove_user current_user
      rescue PlayerLeaveError
        #should flash error info
        respond_with @clash
      else
        respond_with @game
      end
    when 'starting'
      begin
        @clash.start
        redirect_to @clash.get_url(current_user)
        
      rescue ClashStartError
        respond_with @clash
        
      rescue ClashPlayError
        respond_with @clash
        
      end
    when 'playing'
      begin
        redirect_to @clash.get_url(current_user)
      end
    end
  end
  
protected
  def find_clash
    begin
      @clash = Clash.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to games_path
    end
  end
  
end