/**
 * Makes a DOM element clickable to select a breed.
 * 
 * @param {Element} element - The DOM element to make clickable
 * @param {string} breedName - The name of the breed to select when clicked
 * @param {Document} doc - The document object
 * @param {Function} onSelect - The callback function to execute when clicked
 * @return {Function} - An effect function that adds the click handler
 */
export function makeBreedClickable(element) {
  return function(breedName) {
    return function(doc) {
      return function(onSelect) {
        return function() {
          // Style the element to look clickable
          element.style.cursor = "pointer";
          element.style.color = "#0066cc";
          element.style.textDecoration = "underline";
          
          // Add click event listener
          element.addEventListener("click", function() {
            onSelect(breedName)();
          });
        };
      };
    };
  };
}

/**
 * Removes all child nodes from a container element.
 * 
 * @param {Element} container - The container element to clear
 * @return {Function} - An effect function that clears the container
 */
export function clearContainer(container) {
  return function() {
    while (container.firstChild) {
      container.removeChild(container.firstChild);
    }
  };
}