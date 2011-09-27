Readme
------

I'm tired, so I'm going to make this brief.  

Use `rails server` to start up the main app, just like any other rails app

To get realtime Server-Sent Events, make sure to run the node app with `node events.js`

also, in order to make sure they're coming from the same server, you will need to reverse proxy.  Using nginx, make sure to have your nginx.conf looking something like this:

    worker_processes  1;
    
    events {
        worker_connections  1024;
    }
    
    http {
        include       mime.types;
        default_type  application/octet-stream;
    
        sendfile        on;
    
        keepalive_timeout  65;
        
        server {
          listen 80;
          server_name localhost;
          
          location / {
            proxy_pass http://localhost:3000/;
          }
          
          location /events/ {
            proxy_pass http://localhost:3001/;
            proxy_buffering off;
            proxy_read_timeout 1000s;
          }
        }
    }

You will also need a game site or two running for the lobby to communicate back and forth with.  There are a couple of game sites (that aren't fleshed out at all) inside the "Test Games" Folder.  You will need to go inside of these games and run `node server.js` for each one that you want to work with.  I haven't yet seeded the database to include the games, so, with the rails app running, go to "http://localhost/games/", add a new game, and set the "comm" (the URL that we will use as a communication channel to the game server) to "http://localhost:8125/setup.json" for RockPaperScissors and "http://localhost:8126/setup.json" for Chess