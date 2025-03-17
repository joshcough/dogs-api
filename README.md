# To compile

spago build

# To test

spago test

# To build app

spago bundle-app --to dist/app.js --minify

# To run app

npx http-server
open http://127.0.0.1:8080
