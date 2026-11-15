$(document).on('turbo:load', function() {

  var targetUrl = $('.featured_budget_line').attr('data-featured-budget-line');

  if (targetUrl) {
    $.ajax({
      url: targetUrl,
      dataType: 'script'
    });
  }
});
