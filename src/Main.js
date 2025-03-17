export function addBackButtonListener(element) {
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