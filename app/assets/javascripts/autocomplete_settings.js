var AUTOCOMPLETE_DEFAULTS = function(){
  return {
    dataType: 'json',
    minChars: 3,
    showNoSuggestionNotice: true,
    noSuggestionNotice: I18n.t('layout.autocomplete_no_results'),
    preserveInput: true,
    autoSelectFirst: true,
    triggerSelectOnValidInput: false,
    preventBadQueries: false,
    tabDisabled: true
  };
};

// Places files are big: each page downloads and parses each one once
var placesRequests = {};
var loadPlaces = function(placesFile){
  if (!placesRequests[placesFile]) {
    placesRequests[placesFile] = $.getJSON(placesFile).fail(function(){
      delete placesRequests[placesFile];
    });
  }
  return placesRequests[placesFile];
};
