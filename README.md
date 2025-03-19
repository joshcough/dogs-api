# To compile

spago build

# To test

spago test

# To build app

spago bundle-app --to dist/app.js --minify

# To run app

npx http-server
open http://127.0.0.1:8080

# TODO: 

* Refactor BreedList and BreedDetails so that they don't have to make network calls. 
  This can be done a new class that is something like this:

```purescript
class Monad m <= HasDogBreeds m where
    getDogBreeds :: m (Either String (Array BreedFamily))
    getBreedImages :: m (Either String (Array String))
```

And then having an implementation for MonadAff, and another for testing. 

* After that is done, we can write some unit tests for all of the components, 
  and we should be able make the Cache tests so that they don't make network calls either. 

* The DogApi tests are also doing network calls, and technically that is more of an integration test.
  I need to learn about how people manage integration tests in a purescript project.

* I could probably clean up some of the JSON code by learning more about the JSON libraries. I just didn't have time. 
  I suspect that I could have ToJSON and FromJSON instances auto derived. But, it's ok for now.