$(document).on('turbo:load', function() {
  $('.js-table-rows-toggle').on('click', function (e) {
    e.stopPropagation();

    $(this).closest('table').toggleClass('top-10');

    if ($(this).closest('table').hasClass('top-10')) {
      var totalRows = $("#related-entities-budget-table tbody tr").length;
      $(this).text(
        I18n.t('gobierto_budgets.places.show.related_entities_budget.see_all', { number: totalRows })
      );
    } else {
      $(this).text(I18n.t('gobierto_budgets.places.show.related_entities_budget.see_less'));
    }
  })
});
