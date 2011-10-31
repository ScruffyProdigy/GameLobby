$(document).ready(function(){

  $('.chessboard').each(function(index,element){
    var gameID = $(element).attr('game');
    var playerID = $(element).attr('player');
    var link = initializeConnection(gameID,playerID);
    
    function setjQueryProperties(){
      $(element).find('[controllable]').draggable({
        revert:'invalid',
        revertDuration: 10,

        start: function(){
          var pieceID = $(this).attr('piece_id');
          link.getGameInfo('legal moves',{pieceID:pieceID},function(data){
            //do stuff
            if(data.err){
              //flash an error message here
            }else{
              for(move_loc in data.moves){
                var move_data = data.moves[move_loc];
                var $square = $('.'+move_loc);
                
                var dropzone = '<div class="move-target" drop-for="'+move_loc+'"';
                if(move_data.capturedPieces){
                  dropzone += ' capture';
                }
                if(move_data.doPromotion){
                  dropzone += ' promotion';
                }
                dropzone += '>'+$square.html()+'</div>';
                
                $square.html(dropzone);
                $('.move-target').droppable({
                  drop:function(event,ui){
                    var moveLocation = $(this).attr('drop-for');
                    var isPromotion = ($(this).attr('promotion') != undefined);
                    if(isPromotion){
                      $('.blackout').show();
                      $('.promotion').show(200);
                      $('.promotion li').click(function(){
                        $('.blackout').hide();
                        $('.promotion').hide();
                        var newType = $(this).html();
                        newType = newType.replace(/\s+$/,"");
                        link.doGameAction('move piece',{pieceID:pieceID,moveLocation:moveLocation,promotion:newType});
                      });
                    }else{
                      link.doGameAction('move piece',{pieceID:pieceID,moveLocation:moveLocation});
                    }
                  }
                });
              }
            }
          });
        },

        stop: function(){
          $('.move-target').each(function(index,element){
            $(element).parent().html($(element).html());
          });
        }

      });
    }
    setjQueryProperties();
    
    link.onGameAction('moved',function(data){
      var piece = {};
      var $piece = $(element).find(".piece[piece_id='"+data.pieceID+"']");
      var $cell = $("td."+data.location);
      
      piece.id = data.pieceID;
      piece.type = $piece.attr('type');
      piece.color = $piece.attr('color');
      piece.controllable = ($piece.attr('controllable') != undefined);
      $piece.remove();
      
      var new_obj = "<div ";
      new_obj += "class='piece' ";
      new_obj += "type='"+piece.type+"' ";
      new_obj += "color='"+piece.color+"' ";
      if(piece.controllable){
        new_obj += "controllable ";
      }
      new_obj += "piece_id='"+piece.id+"'";
      new_obj += "></div>";

      $cell.append(new_obj);
      setjQueryProperties();
    });

    link.onGameAction('captured',function(data){
      $(element).find("[piece_id='"+data.pieceID+"']").remove();
    });

    link.onGameAction('promoted',function(data){
      $(element).find("[piece_id='"+data.pieceID+"']").attr('type',data.type);
    });
    
    link.onGameAction('your turn',function(data){
      for(var i = 0;i < data.movablePieces.length;i++){
        var pieceID = data.movablePieces[i];
        $('[piece_id='+pieceID+']').attr('movable','movable');
      }
      $(element).attr('yourturn','yourturn');
    });
    
    link.onGameAction('not your turn',function(data){
      $(element).find("[movable]").removeAttr('movable');
      $(element).removeAttr('yourturn');
    });
    
    link.onGameError(function(data){
      $('.blackout').show();
      $('.error').show();
      $('.error p').html(data);
      $('.error li').click(function(){
        $('.blackout').hide();
        $('.error').hide();
      });
    });
  });

});