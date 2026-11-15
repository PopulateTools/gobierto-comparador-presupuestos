// Translations for the JavaScript code. I18n.translations is filled by
// i18n/translations.js, generated with bin/rails i18n:js:export.
var I18n = {
  defaultLocale: "es",
  locale: "es",
  translations: {},

  t: function(key, options) {
    options = options || {};

    var message = this.lookup(this.locale, key);
    if (message === undefined) message = this.lookup(this.defaultLocale, key);
    if (message === undefined) message = options.defaultValue;
    if (message === undefined) return '[missing "' + this.locale + "." + key + '" translation]';

    return this.interpolate(message, options);
  },

  lookup: function(locale, key) {
    return key.split(".").reduce(function(scope, part) {
      return scope === undefined || scope === null ? undefined : scope[part];
    }, this.translations[locale]);
  },

  interpolate: function(message, options) {
    if (typeof message !== "string") return message;

    return message.replace(/%\{(\w+)\}/g, function(placeholder, name) {
      return options[name] === undefined ? placeholder : options[name];
    });
  }
};
