/**
 * Sets the src attribute of an image element.
 * 
 * @param {HTMLImageElement} element - The image element
 * @param {string} url - The image URL to set
 * @return {Function} - An effect function that sets the image source
 */
export function setImageSrc(element) {
  return function(url) {
    return function() {
      element.setAttribute("src", url);
    };
  };
}

/**
 * Adds a click event listener to a DOM element.
 * 
 * @param {Element} element - The element to attach the listener to
 * @param {Function} callback - The callback function to execute on click
 * @return {Function} - An effect function that adds the event listener
 */
export function addClickListener(element) {
  return function(callback) {
    return function() {
      element.addEventListener("click", function() {
        callback();
      });
    };
  };
}

/**
 * Removes all child nodes from a container element.
 * 
 * @param {Element} element - The element to clear
 * @return {Function} - An effect function that clears the element contents
 */
export function clearElementContents(element) {
  return function() {
    while (element.firstChild) {
      element.removeChild(element.firstChild);
    }
  };
}

/**
 * Creates an event handler function that can be attached to DOM elements.
 * 
 * @param {Document} doc - The document object
 * @param {Function} callback - The callback function to wrap
 * @return {Function} - A thunk that returns an event handler function
 */
export function createEventHandler(doc) {
  return function(callback) {
    return function() {
      return function() {
        callback(null)();
      };
    };
  };
}

/**
 * Attaches a click event listener to a back button element.
 * 
 * @param {Element} element - The button element
 * @param {Function} callback - The callback function to execute on click
 * @param {Document} doc - The document object
 * @return {Function} - An effect function that attaches the listener
 */
export function attachBackButtonListener(element) {
  return function(callback) {
    return function(doc) {
      return function() {
        element.addEventListener("click", function() {
          callback();
        });
      };
    };
  };
}

/**
 * Sets the disabled state of a pagination button.
 * 
 * @param {HTMLButtonElement} element - The button element
 * @param {boolean} isDisabled - Whether the button should be disabled
 * @return {Function} - An effect function that updates the button state
 */
export function setPaginationButtonDisabled(element) {
  return function(isDisabled) {
    return function() {
      element.disabled = isDisabled;
    };
  };
}