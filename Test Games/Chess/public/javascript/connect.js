function initializeConnection(gameID,playerID){
  var socket = io.connect('http://127.0.0.1:8126');
  socket.emit('initialize',{gameID:gameID,playerID:playerID});
  var interface = {
    doGameAction: function(type,data){
      socket.emit('action',{type:type,data:data});
    },
    getGameInfo: function(type,data,func){
      socket.emit('info',{type:type,data:data},func);
    },
    onGameAction: function(type,func){
      socket.on(type,func);
    },
    onGameError: function(func){
      socket.on('error',func);
    }
  }
  return interface;
}