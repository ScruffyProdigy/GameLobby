var sys = require('sys');
var express = require('express');
var redis = require('redis');

function easyRedisEventStream(channel){
  return function(req,res){
    if(req.accepts('text/event-stream')){

      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache'
      });

      var client = redis.createClient();
      var eventChannel = channel
      
      if(req.params.id){
        eventChannel += req.params.id;
      }
      sys.log('subscribing to '+eventChannel);
      client.subscribe(eventChannel);

      client.on('message',function(channel,data){
        res.write('data:'+data+'\n\n');
        sys.log(channel+' - '+data);
      });

      req.on('close',function(){
        sys.log('unsubscribing from '+eventChannel)
        client.unsubscribe();
        client.quit();
      });

    }else{
      sys.log('EventStream called from non-EventStream location');
      res.send(404);
    }    
  }
}

var app = express.createServer();

app.get('/games',easyRedisEventStream('games'));
app.get('/games/:id/',easyRedisEventStream('game'));
app.get('/clashes/:id/',easyRedisEventStream('clash'));

app.listen(3001);
sys.log('listening on port 3001');