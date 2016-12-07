(function(window, undefined){
  'use strict';

  window.budgetLineTree = flight.component(function(){
    this.attributes({
      categories: [],
      dropDownIcon: "<i class='fa fa-angle-down'></i>",
      expandIconClass: "fa-plus-square-o",
      collapseIconClass: "fa-minus-square-o",
      state: {
        kind: null,
        area: null
      }
    });

    this.after('initialize', function() {
      this.titlePlaceholder = this.$node.find('h2.sidebar_title');
      this.itemsParent = this.$node.find('div.items');
      this.attr.dataUrl = this.$node.data('api-url');
      var toggle = this.$node.find('[data-toggle]');

      this.$node.find('[data-toggle]').on('click', function(e){
        this.itemsParent.toggle();
        $(e.target).toggleClass('fa-caret-square-o-down').toggleClass('fa-caret-square-o-up');
      }.bind(this));

      $(document).on('click', '[data-category-code]', function(e){
        e.preventDefault();
        $.event.trigger({
          type: "renderBudgetLineCategory",
          code: $(e.target).data('category-code'),
          kind: $(e.target).data('kind'),
          area: $(e.target).data('area')
        });
        $('[data-category-code]').removeClass('active');
        $(e.target).addClass('active');
      }.bind(this));

      $(document).on('click', '[data-select-category]', function(e){
        e.preventDefault();
        var target = $(e.target);
        this.attr.categories = [];
        this.attr.state.kind = target.data('kind');
        this.attr.state.area = target.data('area');
        this.fillPlaceHolder(target);
        target.parents('ul').hide();
        this.itemsParent.show();
        if (toggle.hasClass('fa-caret-square-o-down')) {
            toggle.removeClass('fa-caret-square-o-down').addClass('fa-caret-square-o-up');            
        }
      }.bind(this));

      $(document).on('click', '[data-expand-category]', function(e){
        e.preventDefault();
        var target = $(e.target);
        this.addChildrenPlaceHolder(target);
        this.renderCategories(target.data('expand-category'));
        target.addClass(this.attr.collapseIconClass).removeClass(this.attr.expandIconClass);
        target.data('collapse-category', target.data('expand-category'));
        target.attr('data-collapse-category', target.data('expand-category'));
        target.attr('data-expand-category', null);
        target.removeData('expand-category');
      }.bind(this));

      $(document).on('click', '[data-collapse-category]', function(e){
        e.preventDefault();
        var target = $(e.target);
        target.addClass(this.attr.expandIconClass).removeClass(this.attr.collapseIconClass);
        target.data('expand-category', target.data('collapse-category'));
        target.attr('data-expand-category', target.data('collapse-category'));
        target.attr('data-collapse-category', null);
        target.removeData('collapse-category');
        this.removeCategories(target);
      }.bind(this));

      $(document).on('input propertychange paste', '[data-search-box]', function(e){
        var val = $(e.target).val();
        if(val.length >= 3){
          this.cleanOldCategories();

          for (var area in this.attr.categories) {
            for (var kind in this.attr.categories[area]) {
              var categories = this.attr.categories[area][kind];
              Object.keys(categories).sort().forEach(function(key) {
                if(categories[key].toLowerCase().indexOf(val.toLowerCase()) !== -1){
                  this.addCategory(key, categories[key], area, kind, false);
                }
              }.bind(this));
            }
          }
        } else {
          if(val.length === 0){
            $('[data-selected]').click();
          }
        }
      }.bind(this));

      // Initial state
      $('[data-selected]').click();
      
      // Collapse sidebar on phones
      if (window.innerWidth <= 768) {
        $('.sidebar_wrapper .items').css('display', 'none')
        toggle.removeClass('fa-caret-square-o-up').addClass('fa-caret-square-o-down');     
      }
    });

    this.fillPlaceHolder = function(selectedCategory) {
      this.titlePlaceholder.html('');
      var category = selectedCategory.clone();
      category.html(category.html() + ' ' + this.attr.dropDownIcon);
      category.addClass('current');
      this.titlePlaceholder.html(category);
      this.renderCategories();
    };

    this.renderCategories = function(parentCode) {
      if(this.attr.categories.length === 0){
        $.getJSON(this.attr.dataUrl, function(categories){
          this.attr.categories = categories;
          this.categoriesHandler(parentCode);
        }.bind(this));
      } else {
        this.categoriesHandler(parentCode);
      }
    };

    this.categoriesHandler = function(parentCode){
      var categories = this.attr.categories[this.attr.state.area][this.attr.state.kind];
      if(parentCode === undefined)
        this.cleanOldCategories();
      Object.keys(categories).sort().forEach(function(key) {
        if(parentCode === undefined) {
          if(key.length === 1)
            this.addCategory(key, categories[key], this.attr.state.area, this.attr.state.kind, true);
        }
        else {
          parentCode = parentCode.toString();
          if(key.length === parentCode.length + 1 && key.substr(0, parentCode.length) === parentCode) {
            var target = this.$node.find('table[data-insert-subcategories="'+parentCode+'"] tr:last');
            this.addSubCategory(target, key, this.attr.state.area, this.attr.state.kind, categories[key]);
          }
        }
      }.bind(this));
    };

    this.cleanOldCategories = function(){
      this.itemsParent.find('tr').not('tr[data-search-box]').each(function(){
        this.remove();
      });
    };

    this.addCategory = function(categoryCode, categoryName, area, kind, addExpand){
      var lastTr = this.itemsParent.find('tr:last');
      var html = '<tr><td class="item_name">' +
                 (addExpand ? '<i class="fa '+this.attr.expandIconClass+'" data-expand-category="'+categoryCode+'"></i>' : '') +
                 '<a href="#" data-area="'+area+'" data-kind="'+kind+'" data-category-code="'+categoryCode+'">'+categoryName+'</a></td></tr>';
      $(html).insertAfter(lastTr);
    };

    this.addSubCategory = function(target, categoryCode, area, kind, categoryName){
      var html = '<tr><td class="item_name"><i class="fa '+this.attr.expandIconClass+'" data-expand-category="'+categoryCode+'"></i>' +
                 '<a href="#" data-area="'+area+'" data-kind="'+kind+'" data-category-code="'+categoryCode+'">'+categoryName+'</a></td></tr>';
      $(html).insertAfter(target);
    };


    this.addChildrenPlaceHolder = function(target) {
      $('<tr class="child_group"><td colspan="5"><div class="child_tb_cont"><table data-insert-subcategories="'+target.data('expand-category')+'"><tr></tr></table></div></td></tr>').appendTo(target.parent('td'));
    };

    this.removeCategories = function(target){
      target.parent('td').find('tr').each(function(){
        $(this).remove();
      });
    };
  });



  $(function() {
    window.budgetLineTree.attachTo('[data-budget-line-categories-tree]');
  });

})(window);
