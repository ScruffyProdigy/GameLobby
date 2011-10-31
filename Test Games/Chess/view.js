var sys = require('sys');
var fs = require('fs');
var path = require('path');
var jade = require('jade');

module.exports.render = function(view_name,locals,errfunc,successfunc){
  var file_name = path.join(__dirname,'views',view_name);
  fs.readFile(file_name,function(err,data){
    if(err){
      sys.log('error reading file');
      errfunc(data);
    }else{
      successfunc(jade.compile(data,{filename:file_name,pretty:true})(locals));
    }
  });
}