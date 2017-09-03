require! aea: {sleep}

Ractive.components['r-head'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-head')

Ractive.components['r-body'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-body')

Ractive.components['r-foot'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-foot')

Ractive.components['r-row'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-row')
    oncomplete: ->
        r-table = @find-container \r-table
        r-table.fire \updateColNames


Ractive.components['r-col'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-col')

Ractive.components['r-head-col'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-head-col')

Ractive.components['r-table'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug', '#r-table')
    isolated: yes
    oninit: ->
        @on do
            updateColNames: ->
                cols = $ @find 'thead > tr:last-of-type' .children!
                if cols.length is 0
                    console.error "Column names are not found, missing thead > tr > th?"
                col-names = [..inner-text for cols]
                $ @find 'tbody' .children \tr .each (i, row) ->
                    $ row .children \td .each (i, col) ->
                        $ col .attr \data-th, col-names[i]
    oncomplete: ->
        /*
        r-table = $ @find \.r-table
        parent-width = r-table.parent().inner-width()
        width = r-table.width()
        @set \width, width
        @set \parentWidth, parent-width

        tablet-break-point = 600px
        mobile-break-point = 400px

        if parent-width > tablet-break-point
            r-table.remove-class \r-table-tablet
            r-table.remove-class \r-table-mobile
        if parent-width > mobile-break-point and parent-width <= tablet-break-point
            # this is tablet
            r-table.add-class \r-table-tablet
            r-table.remove-class \r-table-mobile
        else if parent-width <= mobile-break-point
            # this is mobile
            r-table.remove-class \r-table-tablet
            r-table.add-class \r-table-mobile

        */



    data: ->
        width: null
        parent-width: null
