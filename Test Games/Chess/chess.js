var sys = require('sys');


var mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/chess');

/*************************
*
*  Mongo Schemas!
*
*************************/
var Schema = mongoose.Schema;
var ObjectId = Schema.ObjectId;

var view = require('./view.js');

var PieceSchema = new Schema({
  owner: {type:ObjectId,required:true}
  ,type: {type:String,required:true,enum:['pawn','rook','knight','bishop','queen','king']}
  ,location: {type:String,required:true,match:/[a-h][1-8]/}
  ,moved: {type:Boolean,default:false}
});

var PlayerSchema = new Schema({
  url: {type:String,required:true}
  ,color: {type:String,required:true,enum:['white','black']}
});

var GameSchema = new Schema({
  players: [PlayerSchema]
  ,pieces: [PieceSchema]
  ,current_player: {type:Number,default:0}
});

mongoose.model('Game',GameSchema);

var Game = mongoose.model('Game');

/****************************************
*
* Data for Game Engine
*
*****************************************/
var default_pieces = [
  {owner:'white',type:'rook',location:'a1'}  
  ,{owner:'white',type:'knight',location:'b1'}
  ,{owner:'white',type:'bishop',location:'c1'}
  ,{owner:'white',type:'queen',location:'d1'} 
  ,{owner:'white',type:'king',location:'e1'}  
  ,{owner:'white',type:'bishop',location:'f1'}
  ,{owner:'white',type:'knight',location:'g1'}
  ,{owner:'white',type:'rook',location:'h1'}  
  ,{owner:'white',type:'pawn',location:'a2'}  
  ,{owner:'white',type:'pawn',location:'b2'}  
  ,{owner:'white',type:'pawn',location:'c2'}  
  ,{owner:'white',type:'pawn',location:'d2'}  
  ,{owner:'white',type:'pawn',location:'e2'}  
  ,{owner:'white',type:'pawn',location:'f2'}  
  ,{owner:'white',type:'pawn',location:'g2'}  
  ,{owner:'white',type:'pawn',location:'h2'}  
  ,{owner:'black',type:'pawn',location:'a7'}  
  ,{owner:'black',type:'pawn',location:'b7'}  
  ,{owner:'black',type:'pawn',location:'c7'}  
  ,{owner:'black',type:'pawn',location:'d7'}  
  ,{owner:'black',type:'pawn',location:'e7'}  
  ,{owner:'black',type:'pawn',location:'f7'}  
  ,{owner:'black',type:'pawn',location:'g7'}  
  ,{owner:'black',type:'pawn',location:'h7'}  
  ,{owner:'black',type:'rook',location:'a8'}  
  ,{owner:'black',type:'knight',location:'b8'}
  ,{owner:'black',type:'bishop',location:'c8'}
  ,{owner:'black',type:'queen',location:'d8'} 
  ,{owner:'black',type:'king',location:'e8'}  
  ,{owner:'black',type:'bishop',location:'f8'}
  ,{owner:'black',type:'knight',location:'g8'}
  ,{owner:'black',type:'rook',location:'h8'}  
];

function displayBoard(board){
  for(var y = 0;y < 8;y++){
    var line = "|";
    for(var x = 0;x < 8;x++){
      if(board[x][y][0]){
        line += board[x][y][0].type+'|';
      }else{
        line += "-----|"
      }
    }
    sys.log(line);
  }
}


function DefaultChessView(color){
  this.viewX = this.boardViews[color].x;
  this.viewY = this.boardViews[color].y;
}

DefaultChessView.prototype.boardViews = {
  white:{
    x:['a','b','c','d','e','f','g','h']
    ,y:['1','2','3','4','5','6','7','8']
  }
  ,black:{
    x:['a','b','c','d','e','f','g','h']
    ,y:['8','7','6','5','4','3','2','1']
  }
}

DefaultChessView.prototype.getXandY = function(loc,func){
  func(this.viewX.indexOf(loc[0]),this.viewY.indexOf(loc[1]));
}

DefaultChessView.prototype.getLocString = function(x,y){
  return this.viewX[x]+this.viewY[y];
}

function ChessBoard(game,player){
  this.view = new DefaultChessView(player.color);
  this.game = game;
  this.me = player;
  if(this.game.players[0]._id.equals(player._id)){
    this.him = this.game.players[1];
  }else{
    this.him = this.game.players[0];
  }
  this.resetBoard();
}

ChessBoard.prototype.clearBoard = function(){
  this.board = new Array;
  for(var x = 0;x < 8;x++){
    this.board[x] = new Array;
    for(var y = 0;y < 8;y++){
      this.board[x][y] = new Array;
    }
  }
}

ChessBoard.prototype.resetBoard = function(){
  this.clearBoard();
  this.addPieces(this.game.pieces);
}

ChessBoard.prototype.addPiece = function(piece){
  var self = this;
  this.view.getXandY(piece.location,function(x,y){
    self.board[x][y].push(piece);
  });
}

ChessBoard.prototype.removePiece = function(piece){
  var self = this;
  this.view.getXandY(piece.location,function(x,y){
    var new_square = new Array();
    for(var i = 0;i < self.board[x][y].length;i++){
      var this_piece = self.board[x][y][i];
      if(!this_piece._id.equals(piece._id)){
        new_square.push(this_piece);
      }
    }
    self.board[x][y] = new_square
  });
}

ChessBoard.prototype.movePiece = function(piece,x,y){
  this.removePiece(piece);
  this.board[x][y].push(piece);
}


ChessBoard.prototype.makeMove = function(dataForUser){
  var self = this;
  this.view.getXandY(dataForUser.destination,function(x,y){
    self.movePiece(dataForUser.movingPiece,x,y);
  });
  if(dataForUser.comoves){
    for(var i = 0;i < dataForUser.comoves;i++){
      var comove = dataForUser.comoves[i];
      var other_piece = board.pieces.id(comove.piece);
      this.getXandY(comove.loc,function(newX,newY){
        this.move_piece(other_piece,newX,newY);
      });
    }
  }
  if(dataForUser.capturedPieces){
    for(var i = 0;i < dataForUser.capturedPieces.length;i++){
      var capturedPiece = dataForUser.capturedPieces[i];
      this.removePiece(capturedPiece);
    }
  }
}


ChessBoard.prototype.addPieces = function(pieces){
  for(var i = 0;i < pieces.length;i++){
    this.addPiece(pieces[i]);
  }
}

ChessBoard.prototype.getPieceLoc = function(piece,func){
  this.view.getXandY(piece.location,func);
}

ChessBoard.prototype.getPieces = function(x,y){
  return this.board[x][y].slice(0);
}

ChessBoard.prototype.isClear = function(x,y){
  return this.board[x][y].length == 0;
}

ChessBoard.prototype.isOff = function(x,y){
  if(x < 0){
    return true;
  }
  if(x >= 8){
    return true;
  }
  if(y < 0){
    return true;
  }
  if(y >= 8){
    return true;
  }
}

ChessBoard.prototype.getPlayerMoves = function(player,func,options){
  var pieces = [];
  for(var x = 0;x < 8;x++){
    for(var y = 0;y < 8;y++){
      var square = this.board[x][y];
      for(var i = 0;i < square.length;i++){
        var piece = square[i];
        if(piece.owner.equals(player._id)){
          pieces.push(piece);
        }
      }
    }
  }
  for(var i = 0;i < pieces.length;i++){
    var piece = pieces[i];
    this.getPieceMoves(piece,function(loc,data){func(piece,loc,data)},options);
  }
}

ChessBoard.prototype.isChecking = function(attackingPlayer){
  var result = false;
  this.getPlayerMoves(attackingPlayer,function(movingPiece,loc,data){
    if(data.capturedPieces){
      for(var i = 0;i < data.capturedPieces.length;i++){
        var capturedPiece = data.capturedPieces[i];
        if(capturedPiece.type == 'king'){
          sys.log("*-* check found at "+loc+" from a "+attackingPlayer.color+" "+movingPiece.type+" at "+movingPiece.location);
          result = true;
        }
      }
    }
  },{postfilters:[],prefilters:[onlyCapture]});
  return result;
}

ChessBoard.prototype.getPieceMoves = function(piece,func,options){
  options = options || {};
  var self = this;
  var moves = new MoveGenerator(piece);
  this.getPieceLoc(piece,function(startingX,startingY){
    moves.listMoves(piece,startingX,startingY,function(x,y,moveFilters){
      var owner = self.game.players.id(piece.owner);
      sys.log((options.prefilters ? "" : "***")+'find moves for '+owner.color+' '+piece.type+'('+piece.location+') to '+x+','+y);
      var prefilters = [recordBasicInfo,isOnTheBoard,findCapturedPieces];
      var midfilters = options.prefilters || []
      var postfilters = options.postfilters || [AmIInCheck];
      var filters = prefilters.concat(moveFilters,postfilters);
      filters.push(function(board,piece,x,y,dataForUser,next){
        func(self.view.getLocString(x,y),dataForUser);
        if(dataForUser.capturedPieces && dataForUser.capturedPieces.length > 0){
          sys.log('success');
          return true;
        }else{
          sys.log('success and capture!')
          return false;
        }
      });
      
      var i = 0;
      var result;
      (function callNextFilter(board,piece,x,y,dataForUser){
        var filter = filters[i];
        i++;
        
        var filterResult = filter(board,piece,x,y,dataForUser,function(){
          callNextFilter(board,piece,x,y,dataForUser);
        });
        
        if(filterResult != undefined){
          result = filterResult;
        }
      })(self,piece,x,y,new Object);
      
      return result;
    });
  });
}

function recordBasicInfo(board,piece,x,y,dataForUser,next){
  dataForUser.movingPiece = piece;
  dataForUser.destination = board.view.getLocString(x,y);
  next(); 
}

function isOnTheBoard(board,piece,x,y,dataForUser,next){
  if(board.isOff(x,y)){
    sys.log('off the board');
    return true;
  }
  next();
}

function findCapturedPieces(board,piece,x,y,dataForUser,next){
//  sys.log('capturing pieces at:'+x+','+y);
  var capturedPieces = board.getPieces(x,y);
  var pieceCount = capturedPieces.length;
  if(pieceCount > 0){
    dataForUser.capturedPieces = capturedPieces;
    for(var i = 0; i < dataForUser.capturedPieces.length;i++){
      var other_piece = dataForUser.capturedPieces[i];
//      sys.log('captured piece:'+sys.inspect(other_piece));
      if(other_piece.owner.equals(piece.owner)){
        sys.log("can't capture your own pieces")
        return true;
      }
    }
  }
  next();
}

function noCapture(board,piece,x,y,dataForUser,next){
  if(!dataForUser.capturedPieces || dataForUser.capturedPieces.length == 0){
    next();
  }else{
    sys.log('this move cannot capture')
    return true;
  }
}

function onlyCapture(board,piece,x,y,dataForUser,next){
  if(dataForUser.capturedPieces && dataForUser.capturedPieces.length > 0){
    next();
  }else{
    sys.log('this move is only to capture');
    return true;
  }
}

function promotable(board,piece,x,y,dataForUser,next){
  if(y == 7){
    dataForUser.doPromotion = true
  }
  next();
}

function enpassantable(board,piece,x,y,dataForUser,next){
  //needs to check to see if the opponent's last move was a double-move
  //and if so, whether or not this move is onto the space the double-move passed over
  next();
}

function doubleMove(board,piece,x,y,dataForUser,next){
  //needs to store the location that is being moved over
  //so that potential en-passants can capture this
  next();
}


function leftCastle(board,piece,x,y,dataForUser,next){
  var rook = board.getPieces(0,0)[0];
  if(!board.isClear(1,0)){
    return true;
  }
  if(!board.isClear(2,0)){
    return true;
  }
  if(!board.isClear(3,0)){
    return true;
  }
  if(piece.moved){
    return true;
  }
  if(rook.moved){
    return true;
  }
  //god this code is a mess.  We need to check from the opponent's point of view, 
  //whether or not the king is threatened at his current position, or either position he is going to be in to castle
  //from the opponent's point of view, y is 7, not 0
  var testBoard = new ChessBoard(board.game,board.him);
  testBoard.board[5][7].push(piece);
  testBoard.board[6][7].push(piece);
  if(testBoard.isChecking(board.him)){
    return true;
  }
  dataForUser.comoves = [{piece:rook.id,loc:board.view.getLocString(3,0)}];
  next();
}

function rightCastle(board,piece,x,y,dataForUser,next){
  var rook = board.getPieces(7,0)[0];
  if(!board.isClear(6,0)){
    return true;
  }
  if(!board.isClear(5,0)){
    return true;
  }
  if(piece.moved){
    return true;
  }
  if(rook.moved){
    return true;
  }
  //god this code is a mess.  We need to check from the opponent's point of view, 
  //whether or not the king is threatened at his current position, or either position he is going to be in to castle
  //from the opponent's point of view, y is 7, not 0
  var testBoard = new ChessBoard(board.game,board.him);
  testBoard.board[5][7].push(piece);
  testBoard.board[6][7].push(piece);
  if(testBoard.isChecking(board.him)){
    return true;
  } 
  dataForUser.comoves = [{piece:rook.id,loc:board.view.getLocString(5,0)}];
  next();
}

function IsHeInCheck(board,piece,x,y,dataForUser,next){
  var newBoard = newChessBoard(board.game,board.me);
  newBoard.makeMove(dataForUser);
  if(newBoard.isChecking(board.me)){
    dataForUser.isCheck = true;
  }
  next();
}

function AmIInCheck(board,piece,x,y,dataForUser,next){
  var newBoard = new ChessBoard(board.game,board.him);
  newBoard.makeMove(dataForUser);
  if(newBoard.isChecking(board.him)){
    sys.log("that would leave me in check")
    return true;
  }else{
    next();
  }
}

function longChessPath(dx,dy){
  return function(piece,x,y,func){
    for(var i = 0;i < 8;i++){
      x += dx;
      y += dy;
      if(func(x,y,[])){
        break;
      }
    }
  }
}

function shortChessPath(dx,dy){
  return function(piece,x,y,func){
    func(x+dx,y+dy,[]);
  }
}


function pawnPath(){
  return function(piece,x,y,func){
    if(func(x,y+1,[noCapture,promotable]) === false && !piece.moved){
      func(x,y+2,[noCapture,doubleMove]);
    }
    func(x-1,y+1,[enpassantable,onlyCapture,promotable]);
    func(x+1,y+1,[enpassantable,onlyCapture,promotable]);
  }
}

function castlePath(){
  return function(piece,x,y,func){
    if(!piece.moved){
      func(x-2,y,[leftCastle]);
      func(x+2,y,[rightCastle]);
    }
  }
}

function MoveGenerator(piece){
  this.paths = this.moveData[piece.type];
}

MoveGenerator.prototype.moveData = {
  pawn:[
    pawnPath()
  ]
  ,rook:[
    longChessPath(1,0)
    ,longChessPath(0,1)
    ,longChessPath(-1,0)
    ,longChessPath(0,-1)
  ]
  ,knight:[
    shortChessPath(1,2)
    ,shortChessPath(2,1)
    ,shortChessPath(2,-1)
    ,shortChessPath(1,-2)
    ,shortChessPath(-1,-2)
    ,shortChessPath(-2,-1)
    ,shortChessPath(-2,1)
    ,shortChessPath(-1,2)
  ]
  ,bishop:[
    longChessPath(1,1)
    ,longChessPath(-1,1)
    ,longChessPath(-1,-1)
    ,longChessPath(1,-1)
  ]
  ,queen:[
    longChessPath(1,0)
    ,longChessPath(1,1)
    ,longChessPath(0,1)
    ,longChessPath(-1,1)
    ,longChessPath(-1,0)
    ,longChessPath(-1,-1)
    ,longChessPath(0,-1)
    ,longChessPath(1,-1)
  ]
  ,king:[
    shortChessPath(1,0)
    ,shortChessPath(1,1)
    ,shortChessPath(0,1)
    ,shortChessPath(-1,1)
    ,shortChessPath(-1,0)
    ,shortChessPath(-1,-1)
    ,shortChessPath(0,-1)
    ,shortChessPath(1,-1)
    ,castlePath()
  ]
}

MoveGenerator.prototype.listMoves = function(piece,x,y,func){
  for(var i = 0;i < this.paths.length;i++){
    this.paths[i](piece,x,y,func);
  }
}

function getMovablePieces(game,player){
  var board = new ChessBoard(game,player);
  var movablePieces = [];
  board.getPlayerMoves(player,function(movablePiece,loc,data){
    var p_id = movablePiece.id;
    var index = movablePieces.indexOf(p_id);
    if(index == -1){
      movablePieces.push(p_id);
    }
  });
  return movablePieces;
}

function getLegalMoves(game,pieceID){
  sys.log('*******');
  var piece = game.pieces.id(pieceID);
  var player = game.players.id(piece.owner);
  
  var board = new ChessBoard(game,player);
  
  var moves = {};
  
  board.getPieceMoves(piece,function(loc,data){
    moves[loc] = data;
  });
  
  return moves;
}


/*****************************************
*
*  Request Handlers
*
*****************************************/


/**********************************
Creation Request:
  -'user' a string which contains a url to look up any other information you might want
  -'form' will be null the first time the user tries to create a clash, on subsequent attempts, this will be filled out with whatever data you requested
  -'errfunc' if the specified user cannot create the clash with the chosen settings, call this function with the following:
    = feedback as to why the clash cannot be created (a string)
  -'formfunc' if you need more information to determine whether or not the user can create the clash, call this function with the following
    = an object, whose fields are the names of the variables that will be fed back to you.  each field should be an object with the following fields:
      * 'label' - the label of the variable, so the user knows how to fill it out
      * 'type' - the type of variable to fill out.  Currently can be any of the following:
        • 'string' - a string
        • 'hidden' - a hidden variable that will be passed back to you
      * 'value' - used for hidden values.  This is the value passed back to you
  -'successfunc' if the user can create the clash, call this function. You must specify the following in order:
    = the name of the clash (a string)
    = a description of the clash (a string)
    = the playerlists that need to be filled before the clash can start (an array of objects each of the objects must have the following fields:)
      * 'name' the name of the player list
      * 'count' the number of players to fill that list in with
    = (optional) the name of the player list to put the clash creator into (a string) -(defaults to whichever list you declared first if unspecified)
    = (optional) any public information you want the lobby to share (which can allow players to filter through) (an object not currently used.  specification will be created later) -(defaults to null)
    = (optional) any private information you don't want the lobby to share (an object - no specification needed, lobby treats it as a blob of data fed back to you) -(defaults to null)

***********************************/
module.exports.handleCreateRequest = function(user,form,errfunc,formfunc,successfunc){
  sys.log('creating!');
  if(!form){
    form = {};
    form.gamename = {'label':'Game Name','type':'string'};
    form.description = {'label':'Description','type':'string'}
    formfunc(form);
  }else{  
    var playerlists = [];
    playerlists.push({'name':'white','count':1});
    playerlists.push({'name':'black','count':1});
    successfunc(form.gamename,form.description,playerlists);
  }
}

/*******************************
Join Request:
  -'clash' an object, which contains the following fields
    ='publicdata' the public information you specified in the creation request
    ='privatedata' the private information you specified in the creation request
  -'list' a string, which contains the name of the player list (from the ones you specified in the creation request) which the user wishes to join
  -'user' a string, which contains a url that you can look up any other information about the user you want
  -'form' will be null the first time a player attempts, on subsequent attempts, will be filled out with the information you requested in formfunc
  -'errfunc' call if there is the specified user cannot join the clash in the specified list, specify the following:
    = a string that gives the user feedback as to why they cannot join
  -'formfunc' call if you need more information to determine whether the user can join the clash.  (doesn't currently work on the lobby side)
  -'successfunc' call if the user can join the clash with the given options.  Specify the following in order:
    = (optional) any public information you want the clash to share (which can allow other players to filter information) (an object not currently used.  specification will be created later) -(defaults to null)
    = (optional) any private information you don't want the clash to share (an object - no specification needed, clash treats it as a blob of data fed back to you) -(defaults to null)

*******************************/
module.exports.handleJoinRequest = function(clash,list,user,form,errfunc,formfunc,successfunc){
  successfunc();
}

/***************************************
Start Request:
  -'clash' an object, which contains the following fields
    ='publicdata' the public information you specified in the creation request
    ='privatedata' the private information you specified in the creation request
  -'players' an object whose fields correspond to the names of the lists you specified during the creation request
    = each of these fields is an array of objects, which contain
      * 'url' a string which contains a url that allows you to look up any extra information about the player that you might want
      * 'publicdata' an object which contains any information that you specified during the join request
      * 'privatedata' an object which contains any information that you specified during the join request 
  -'errfunc' call if there is a problem trying to start the clash specify the following:
    = a string that gives the user feedback as to why the clash couldn't start
  -'successfunc' call after you've succesfully started the clash.  Specify the following in order:
    = the id of the clash
    = an array of objects for each player in the game, of which each object has the following fields:
      * 'url' the URL that has been given to you as an identifier for each player
      * 'id' an id that the user can identify themselves with when trying to access the game information
    
***************************************/
module.exports.new_clash = function(clash,players,errfunc,successfunc){
  var current_game = new Game({});
  
  //add players
  current_game.players.push({url:players.white[0].url,color:'white'});
  current_game.players.push({url:players.black[0].url,color:'black'});
  current_game.save();
  
  //add pieces
  var players = new Object();
  players.white = current_game.players[0];
  players.black = current_game.players[1];
  
  
  for(var i = 0;i < default_pieces.length;i++){
    var current_piece = new Object();
    current_piece.type = default_pieces[i].type;
    current_piece.location = default_pieces[i].location;
    current_piece.owner = players[default_pieces[i].owner]._id;
    current_game.pieces.push(current_piece);
  }
    
  current_game.save(function(err){
    if(err){
      sys.log('Error:'+sys.inspect(err));
      errfunc(err);
    }else{
      successfunc(current_game.id,current_game.players);
    }
  });
}


/*************************************
Get Request:
  -'game_id' the id you specified during the clash starting request
  -'player_id' the id you specified for the current player trying to access the clash
  -'errfunc' call this if the user can't access the clash for some reason.  Specify the following:
    = a string that gives feedback as to why the user can't access the clash
  -'successfunc' call this once the user accesses the clash.  Specify the following:
    = a string which has the html you want to feed to the user
*************************************/
module.exports.get_game = function(game_id,player_id,errfunc,successfunc){
  sys.log('game_id:'+sys.inspect(game_id));
  sys.log('plyr_id:'+sys.inspect(player_id));
  Game.findById(game_id,function(err,game){
    if(err){
      sys.log('err:'+sys.inspect(err));
      errfunc("can't find the specified game");
      return;
    }else{
      player = game.players.id(player_id);
      if(!player){
        errfunc("can't find the specified player");
        return;
      }
      
      var letters = ['a','b','c','d','e','f','g','h'];
      var board = new Object();
      for(var x = 0;x < 8;x++){
        var letter = letters[x];
        for(var y = 1;y <= 8;y++){
          board[letter+y] = new Array;
        }
      }
      
      for(var iPiece = 0;iPiece < game.pieces.length;iPiece++){
        var piece = game.pieces[iPiece];
        piece.color = game.players.id(piece.owner).color;
        board[piece.location].push(piece);
      }
      
      var movable = [];
      var yourturn = game.players[game.current_player].id == player_id;
      if(yourturn){
        movable = getMovablePieces(game,player); 
      }
      
      view.render('chess.jade',{sys:sys,board:board,game:game,player:player,yourturn:yourturn,movable:movable},errfunc,function(html){
        successfunc(html);
      });
    }
  });
}
/*******************************
Actions
  each field corresponds to a name of an action, which can be called from the view javascript with link.doGameAction(action,data)
    -'gameID' the id of the game that the action is occuring on
    -'playerID' the id of the player that is attempting to do the action
    -'data' the information you sent regarding what the action is
    -'errfunc' call this if the action cannot be performed specify the following, to send back information to the user
      = any data that will help you later give feedback to the user about why the action could not be performed
    -'updatefunc' call this if the action succeeds in order to update all users of the game as to the new state of the game.  Specify the following:
      = a string that indicates what the change is
      = an object which will contain all of the information you will need to make the changes for each player
      = (optional) options on how to send the message.  Can contain the following fields:
        *'only' an array of player ids.  Will only send the message to the specified players
        *'except' an array of player ids.  Will not the the message to the specified players
*******************************/
module.exports.actions = {
  'move piece':function(gameID,playerID,data,errfunc,updatefunc){
    sys.log('data:'+sys.inspect(data));
    sys.log('moving piece:\''+data.pieceID+'\' to '+data.moveLocation);
    Game.findById(gameID,function(err,game){
      if(err){
        errfunc("couldn't contact server");
        return;
      }
      
      var currentPlayerID = game.players[game.current_player]._id;
      if(currentPlayerID != playerID){
        errfunc("wait your turn, bitch!");
        return;
      }
      
      var piece = game.pieces.id(data.pieceID);
      if(piece.owner != playerID){
        errfunc("That's not your piece");
        return;
      }
      
      var updates = [];
      var moves = getLegalMoves(game,data.pieceID);
      var move = moves[data.moveLocation];
      if(!move){
        errfunc("Illegal Move!");
        return;
      }
      
      updates.push(function(next){  
        piece.location = data.moveLocation;
        piece.moved = true;
        game.save(function(err){
          if(err){
            errfunc('Move failed! Database error:'+err);
          }else{
            updatefunc('moved',{pieceID:data.pieceID,location:data.moveLocation});
            next();
          }
        });
      });
      
      if(move.capturedPieces){
        sys.log('captured '+move.capturedPieces.length+' pieces');
        for(var i = 0;i < move.capturedPieces.length;i++){
          var capturedPiece = move.capturedPieces[i];
          sys.log('capturing piece:'+sys.inspect(capturedPiece));
          updates.push(function(next){
            game.pieces.id(capturedPiece).remove();
            game.save(function(err){
              if(err){
                errfunc('Capture Failed! Database error:'+err);
              }else{
                updatefunc('captured',{pieceID:capturedPiece.id});
                next();
              }
            });
          });   
        }
      }
      
      if(move.comoves){
        sys.log('there were '+move.comoves.length+' comoves found!');
        for(var i = 0;i < move.comoves.length;i++){
          var comove = move.comoves[i];
          var comovingPiece = game.pieces.id(comove.piece);
          sys.log('comoving piece:'+sys.inspect(comovingPiece));
          updates.push(function(next){
            comovingPiece.location = comove.loc;
            comovingPiece.moved = true;
            game.save(function(err){
              if(err){
                errfunc('Comove failed! Database error:'+err);
              }else{
                updatefunc('moved',{pieceID:comove.piece,location:comove.loc});
                next();
              }
            })
          });
        }
      }
      
      if(move.doPromotion){
        updates.push(function(next){
          piece.type = data.promotion;
          game.save(function(err){
            if(err){
              sys.log('promotion failed:'+piece.type)
              errfunc('Promotion to '+piece.type+' Failed! Database error:'+err);
            }else{
              updatefunc('promoted',{pieceID:data.pieceID,type:data.promotion});
              next();
            }
          });
        });
      }

      updates.push(function(next){
        var oldPlayer = game.players[game.current_player];
        game.current_player++;
        while(game.current_player >= game.players.length){
          game.current_player -= game.players.length;
        }
        var newPlayer = game.players[game.current_player];
        var movablePieces = getMovablePieces(game,newPlayer);

        game.save(function(err){
          if(err){
            errfunc('Player Update Failed! Database error:'+err);
          }else{
            updatefunc('not your turn',{},{only:[oldPlayer.id]});
            updatefunc('your turn',{movablePieces:movablePieces},{only:[newPlayer.id]});
            next();
          }
        });
      });
      
      
      var i = 0;
      (function callNextUpdate(){
        var update = updates[i];
        i++;
        if(update){
          update(function(){
            callNextUpdate();
          });  
        }        
      })();
      
    });
  }
};


/***********************************
Get Info:
  Each field should correspond to the name of some type of information gathering request, which can be called from link.getGameInfo('info type',data)
    'gameID' - the ID of the game that they are getting information from
    'playerID' - the ID of the player that is trying to get the information
    'data' - the information you sent through getGameInfo
    'errfunc' - call this if the information cannot be gotten.  Specify the following:
      - an object or string that can help you figure out what the problem was
    'successfunc' - call this if you are able to gather the information.  Specify the following:
      - an object that contains the information you requested from the view
***********************************/
module.exports.get_info = {
  'legal moves':function(gameID,playerID,data,errfunc,successfunc){
    sys.log('gameID:'+gameID);
    sys.log('playerID'+playerID);
    sys.log('data:'+sys.inspect(data));
    Game.findById(gameID,function(err,game){
      if(err || !game){
        errfunc("couldn't contact server");
      }else{
        currentPlayerID = game.players[game.current_player]._id;
        sys.log('current player: '+currentPlayerID);
        sys.log('checking player:'+playerID);
        if(currentPlayerID != playerID){
          errfunc("wait your turn, bitch!");
        }else{
          var moves = getLegalMoves(game,data.pieceID);
          sys.log('found moves:'+sys.inspect(moves));
          successfunc({moves:moves});
        }
      }
    });
  }
};