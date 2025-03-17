export function setImageSrc(element) {
  return function(url) {
    return function() {
      element.setAttribute("src", url);
    };
  };
}

export function addClickListener(element) {
  return function(callback) {
    return function() {
      element.addEventListener("click", function() {
        callback();
      });
    };
  };
}

export function clearContainer(element) {
  return function() {
    while (element.firstChild) {
      element.removeChild(element.firstChild);
    }
  };
}

export function makeClickHandler(doc) {
  return function(callback) {
    return function() {
      return function() {
        callback(null)();
      };
    };
  };
}