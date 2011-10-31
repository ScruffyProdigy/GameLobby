// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  
  //games
  $('section.games').each(function(){
    var gamebox = this;
    var source = new EventSource('/events/games/');
    source.onmessage = function(event){
      event = JSON.parse(event.data);
      switch(event.type){
        case 'new_game':
          $(gamebox).find('ul.games').first().append('<li class="game_'+event.id+'"><a href="/games/'+event.id+'">'+event.name+'</a></li>');
        break;
        
        case 'game_gone':
          $(gamebox).find('li.game_'+event.id).remove();
        break;
      }
    }
  });
  
  // game / clashes
  $('section.game').each(function(){
    var gamebox = this;
    var game_id = $(gamebox).attr('game_id');
    var source = new EventSource('/events/games/'+game_id+'/');
    source.onmessage = function(event){
      event = JSON.parse(event.data);
      switch(event.type){
        case 'new_clash':
          $(gamebox).find('ul.clashes').first().append('<a href="/clashes/'+event.id+'" class="clash'+event.id+'"><li>'+event.name+'</li></a>');
        break;
        
        case 'clash_gone':
          $(gamebox).find('a.clash'+event.id).remove();
        break;
      }
    }
  });
  
  // clash / players
  $('section.clash').each(function(){
    var clashbox = this;
    var clash_id = $(clashbox).attr('clash_id');
    
    $(clashbox).find('.hideme').hide()
    
    var source = new EventSource('/events/clashes/'+clash_id+'/');
    source.onmessage = function(event){
      event = JSON.parse(event.data);
      switch(event.type){
        case 'new_player':
          var lists = $(clashbox).find('.player_list');
          list = lists.filter('[list_name="'+event.list+'"]');
          list.find('ul.players').first().append('<a href="/users/'+event.user_id+'" class="player'+event.id+'"><li>'+event.name+'</li></a>');
          if(event.full){
            list.find('.join_clash').hide();
          }
          if(event.startable){
            $(clashbox).find('.start_clash').show();
          }
        break;
        
        case 'player_gone':
          var leaving_player = $(clashbox).find('a.player'+event.id);
          var list = leaving_player.closest('.player_list');
          leaving_player.remove();  //player is gone
          list.find('.join_clash').show(); //show the join button (if it was hidden before)
          $(clashbox).find('.start_clash').hide(); //hide the start button (if it was visible before)
        break;
        
        case 'clash_starting':
          $(clashbox).find('.start_clash').hide();
          $(clashbox).find('.leave_clash').hide();
          $(clashbox).find('.head_to_clash').show();
        break;
      }
    }
  });
  
});