export function setButtonDisabled(element) {
  return function(isDisabled) {
    return function() {
      element.disabled = isDisabled;
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
