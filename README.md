# Dogs API For Panoramic by Josh Cough

## Commands

* To compile - `npm run compile`
* To test - `npm run test`
* To build and run app - `npm run start`

## TODO: 

* Refactor BreedList and BreedDetails so that they don't have to make network calls. 
  This can be done a new class that is something like this:

```purescript
class Monad m <= HasDogBreeds m where
    getDogBreeds :: m (Either String (Array BreedFamily))
    getBreedImages :: m (Either String (Array String))
```

And then having an implementation for MonadAff, and another for testing. 

* After that is done, we can write some unit tests for all of the components, 
  and we should be able to make the Cache tests so that they don't make network calls either. 

* The DogApi tests are also doing network calls, and technically that is more of an integration test.
  I need to learn about how people manage integration tests in a purescript project.

* I could probably clean up some of the JSON code by learning more about the JSON libraries. I just didn't have time. 
  I suspect that I could have ToJSON and FromJSON instances auto derived. But, it's ok for now.