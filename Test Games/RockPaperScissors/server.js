var sys = require('sys');
var express = require('express');

var app = express.createServer();
app.configure(function(){
    app.use(express.methodOverride());
    app.use(express.bodyParser());
    app.use(app.router);
});

app.get('/',function(req,res){
});

app.post('/setup.json',function(req,res){
  sys.log('body:'+sys.inspect(req.body));
  result = null;
  switch(req.body.type){
    case 'game':
      result = {'status':'form','data':{'gamename':{'label':'Game Name','type':'string'},'description':{'label':'Description','type':'string'},'formtype':{'type':'hidden','value':'newgame'}}};
    break;
    
    case 'gameform':
      req.body.data = JSON.parse(req.body.data);
      result = {'status':'game','data':{'name':req.body.data.gamename,'description':req.body.data.description,'lists':[{'name':'players','count':2}],'start':'players'}};
    break;
    
    case 'join':
      result ={'status':'join','data':{}};
    break;
    
    case 'joinform':
    break;
    
    case 'start':
      result = {'status':'start','data':{'url':'http://127.0.0.1:8125/game'}};
    break;
  }
  if(result != null){
    result = JSON.stringify(result);
    sys.log("Return Value: "+result);
    res.send(result);
  }else{
    sys.log("No return value");
  }
});

app.listen(8125);