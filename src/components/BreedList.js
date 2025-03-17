export function makeClickable(element) {
  return function(breedName) {
    return function(doc) {
      return function(onSelect) {
        return function() {
          element.style.cursor = "pointer";
          element.style.color = "#0066cc";
          element.style.textDecoration = "underline";

          element.addEventListener("click", function() {
            onSelect(breedName)();
          });
        };
      };
    };
  };
}

export function clearContainer(container) {
  return function() {
    while (container.firstChild) {
      container.removeChild(container.firstChild);
    }
  };
}