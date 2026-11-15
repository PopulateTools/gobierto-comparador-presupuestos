//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require turbolinks
//= require i18n/translations
//= require velocity.min
//= require velocity.ui.min
//= require velocity_settings
//= require tipsy
//= require accounting.min
//= require accounting_settings
//= require jquery.autocomplete
//= require autocomplete_settings
//= require gobierto_budgets/vendor/js.cookie
//= require mustache.min
//= require flight-for-rails
//= require d3-jetpack
//= require d3-legend.min
//= require topojson-client.min
//= require slimselect.min
//= require chroma.min
//= require gobierto_budgets/vendor/select2.min
//= require underscore-min
//= require klass
//= require gobierto_budgets/vendor/jquery.inview
//= require jquery.magnific-popup.min
//= require gobierto_budgets/budgetCategoriesDictionary
//= require gobierto_budgets/vendor/nouislider
//= require gobierto_budgets/getBudgetLevelData
//= require gobierto_budgets/visBubbleLegend
//= require gobierto_budgets/visSlider
//= require gobierto_budgets/vis_bubbles
//= require gobierto_budgets/vis_treemap
//= require gobierto_budgets/vis_lineas_tabla
//= require gobierto_budgets/vis_evo_line
//= require gobierto_budgets/history
//= require gobierto_budgets/compare
//= require gobierto_budgets/ui
//= require gobierto_budgets/execution
//= require gobierto_budgets/featured_budget_lines
//= require gobierto_budgets/ranking
//= require gobierto_budgets/analytics
//= require gobierto_budgets/vendor/iframeResizer/iframeResizer.contentWindow.min
//= require gobierto_budgets/maps
//= require gobierto_budgets/table
//= require_directory ../components/

$(document).on('turbolinks:load', function() {
  addScrollToLinksBehavior();
});

function addScrollToLinksBehavior() {
  $('.js-scrollto').click(function(e) {
    e.preventDefault();
    var targetId = '#' + this.href.split('#')[1]
    $(targetId).velocity('scroll', { duration: 500, offset: 0 });
  });
}
