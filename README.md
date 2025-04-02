# Dogs API For Panoramic by Josh Cough

## Requirements

Dog Breed Api

See https://dog.ceo/dog-api/documentation/ for general Api documentation. 

Write a small frontend application that:

* Can be in one of two basic user interface states.
    * Dog Breed List
        * Loads the list of dog breeds/sub-breeds if not already loaded dog.ceo/api/breeds/list/all
        * Displays the list of breeds with sub-breed names displayed. The display styling need not be fancy  but the list should be sorted alphabetically.
        * The user can transition to Dog Breed Details by clicking on a specific breed in the list.
    * Dog Breed Details
        * The user can return to the Dog Breed List state.
        * Loads image list from dog.ceo/api/breed/{breed}/images. A specific breed should be loaded at  most once per session.
        * Displays the total number of images for the breed.
        * Displays 20 images at a time
        * Allows the user to page forward and backward with Previous and Back buttons. The buttons  should only be enabled when appropriate.  
* General Notes
    * Make a call to the underlying Api for a specific Url only once per application session / instance.
      The same data should not be fetched twice for the same run of the application so be certain to model that. 
    * Always indicate to the user when data is loading and disallow interactions while loading.
    * Do not worry about fancy styling.
    * In a real application these states would be represented as routes but that complexity has been excluded 
      here to reduce the burden of plumbing code.

## Commands

* To compile - `npm run compile`
* To test - `npm run test`
* To build and run app - `npm run start`

## Troubleshooting

run `npm install xhr2` if you see the following error:

```
node:internal/modules/package_json_reader:267
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^
Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'xhr2' imported from /Users/joshuacough/work/panoramic_testing_1/output/Affjax.Node/foreign.js
    at Object.getPackageJSONURL (node:internal/modules/package_json_reader:267:9)
    at packageResolve (node:internal/modules/esm/resolve:768:81)
    at moduleResolve (node:internal/modules/esm/resolve:854:18)
    at defaultResolve (node:internal/modules/esm/resolve:984:11)
    at ModuleLoader.defaultResolve (node:internal/modules/esm/loader:688:12)
    at #cachedDefaultResolve (node:internal/modules/esm/loader:612:25)
    at ModuleLoader.resolve (node:internal/modules/esm/loader:595:38)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:248:38)
    at ModuleJob._link (node:internal/modules/esm/module_job:136:49) {
  code: 'ERR_MODULE_NOT_FOUND'
```

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