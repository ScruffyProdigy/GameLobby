var sys = require('sys');
var express = require('express');
var game = require('./chess.js');
var io = require('socket.io');
var redis = require('redis');
var redisclient = redis.createClient();


var app = express.createServer();
app.configure(function(){
    app.use(express.methodOverride());
    app.use(express.bodyParser());
    app.use(app.router);
    app.use(express.static(__dirname+'/public'));
});

app.get('/',function(req,res){
});

app.post('/setup.json',function(req,res){
  sys.log('body:'+sys.inspect(req.body));
  function errfunc(err){
    res.send({status:'fail','data':{'error':err}});
  };
  
  function formfunc(form){
    res.send({status:'form','data':form});
  };
  
  function createfunc(name,description,lists,startinglist,publicInfo,privateInfo){
    var response = {};
    response.name = name;
    response.description = description;
    response.lists = lists;
    if(startinglist){
      response.start = startinglist;
    }else{
      response.start = lists[0].name;
    }
    if(publicInfo){
      response.publicdata = publicInfo;
    }
    if(privateInfo){
      response.privatedata = privateInfo;
    }
    res.send({status:'game','data':response});
  };
  
  function joinfunc(publicInfo,privateInfo){
    var response = {};
    if(publicInfo){
      response.publicdata = publicInfo;
    }
    if(privateInfo){
      response.privatedata = privateInfo;
    }
    res.send({status:'join','data':response});
  };
  
  function startfunc(gameID,players){
    sys.log('HTTP Request:'+sys.inspect(req));
    var response = {};
    response.url = 'http://127.0.0.1:8126/'+'game/'+gameID;
    response.players = {};
    for(var i = 0;i < players.length;i++){
      response.players[players[i].url] = players[i].id;
    }
    res.send({'status':'start','data':response});
  };
  
  result = null;
  switch(req.body.type){
    case 'game':
      game.handleCreateRequest(req.body.user,null,errfunc,formfunc,createfunc);
    break;
    
    case 'gameform':
      game.handleCreateRequest(req.body.user,JSON.parse(req.body.data),errfunc,formfunc,createfunc);
    break;
    
    case 'join':
      game.handleJoinRequest(req.body.clash,req.body.list,req.body.user,null,errfunc,formfunc,joinfunc);
    break;
    
    case 'joinform':
      game.handleJoinRequest(req.body.clash,req.body.list,req.body.user,JSON.parse(req.body.data),errfunc,formfunc,joinfunc);
    break;
    
    case 'start':
      game.new_clash(JSON.parse(req.body.clash),JSON.parse(req.body.players),errfunc,startfunc);
    break;
    
    default:
      errfunc('unknown request type');
    break;
  }
});

app.get('/game/:id',function(req,res){
  var errfunc = function(err){
    res.send(err);
  };
  game.get_game(req.params.id,req.query.player,errfunc,function(game){
    sys.log('rendering game!');
    res.send(game);
  });
});

app.listen(8126);

var socketio = io.listen(app).sockets;

socketio.on('connection',function(socket){
  socket.on('initialize',function(data){
    socket.set('game',data.gameID);
    socket.set('player',data.playerID);
    
    var subscriber = redis.createClient();
    subscriber.subscribe('game:'+data.gameID);

    subscriber.on('message', function(channel,message) {
      message = JSON.parse(message);
      var valid = true;
      if(message.only){
        if(message.only.indexOf(data.playerID) < 0){
          valid = false;
        }
      }
      if(message.except){
        if(message.except.indexOf(data.playerID) >= 0){
          valid = false;
        }
      }
      if(valid){
        var message_type = message.type;
        var message_data = message.data;
        socket.emit(message_type,message_data);
      }
    });
  });
  
  socket.on('action',function(data){
    sys.log('action!');
    function errfunc(err){
      socket.emit('error',err);
    }
    socket.get('game',function(err,gameID){
      if(err){
        errfunc("uninitialized game");
        return;
      }
      socket.get('player',function(err,playerID){
        if(err){
          errfunc("uninitialized player");
          return;
        }
        sys.log("doing action! '"+data.type+"'-"+sys.inspect(game.actions[data.type]));
        game.actions[data.type](gameID,playerID,data.data,errfunc,function(action,data,options){
          options = options || {};
          var message = {};
          message.type = action;
          message.data = data;
          if(options.only){
            message.only = options.only;
          }
          if(options.except){
            message.except = options.except;
          }
          redisclient.publish('game:'+gameID,JSON.stringify(message));
        });
      });
    });
  });
  
  socket.on('info',function(data,func){
    sys.log('info!');
    function errfunc(err){
      socket.emit('error',err);
    }
    socket.get('game',function(err,gameID){
      if(err){
        errfunc('uninitialized game');
        return;
      }
      socket.get('player',function(err,playerID){
        if(err){
          errfunc('uninitialized player');
          return;
        }
        sys.log("getting info! '"+data.type+"'-"+sys.inspect(game.get_info[data.type]));
        game.get_info[data.type](gameID,playerID,data.data,errfunc,func);
      });
    });
  });
});