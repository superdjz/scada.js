"""
Design considerations (TO BE COMPLETED)

* Multiple:

    1. If data is not available but `selected-key` is set, dropdown should display
    a loading icon


# Testing procedure:

1. Place 2 dropdown side by side (exact copy of each other)
2. Change one, expect the other to be exactly the same of the one
"""
require! 'prelude-ls': {find, empty, take, compact}
require! 'actors': {RactiveActor}
require! 'aea': {sleep}

require! 'sifter': Sifter
require! '../data-table/sifter-workaround': {asciifold}

Ractive.components['dropdown'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    isolated: yes
    oninit: ->
        @actor = new RactiveActor this, do
            name: "dropdown.#{@_guid}"
            debug: yes

        # map attributes to classes
        for attr, cls of {\multiple, \inline, \disabled, 'fit-width': \fluid}
            if @get attr then @set \class, "#{@get 'class'} #{cls}"

        if @get \key => @set \keyField, that
        if @get \name => @set \nameField, that

        if @get \start-with-loading
            @set \loading, yes

        #@link \selected-item, \item

    onrender: ->
        const c = @getContext @target .getParent yes
        c.refire = yes
        dd = $ @find '.ui.dropdown'
        keyField = @get \keyField
        nameField = @get \nameField
        external-change = no

        small-part-of = (data) ~>
            if data? and not empty data
                take @get('load-first'), data
            else
                []

        update-dropdown = (_new) ~>
            if @get \debug
                @actor.log.log "#{@_guid}: selected key is changed to: ", _new
            <~ set-immediate
            external-change := yes
            <~ :lo(op) ~>
                try
                    throw {code: 'keyempty'} unless _new
                    if @get \multiple
                        dd.dropdown 'set exactly', _new
                        dd.dropdown 'refresh'
                        return op!
                    else
                        if @get \debug => @actor.log.debug "Setting new visual to #{_new}"
                        if empty ((@get \data) or [])
                            if @get \debug => @actor.log.debug "No data yet, not updating dropdown."
                            return
                        item = find (.[keyField] is _new), compact @get \dataReduced
                        unless item
                            item = find (.[keyField] is _new), @get \data
                            unless item
                                # no such key can be found
                                @set \nomatch, true
                                throw {code: \nomatch}
                            else
                                @push \dataReduced, item
                        if item
                            @set \nomatch, false

                        @set \item, item
                        unless (@get \selected-key) is _new
                            # a new selected-key is set by the async handler,
                            # so set selected-key explicitly
                            @set \selected-key, _new
                        <~ set-immediate
                        dd.dropdown 'set selected', _new
                        dd.dropdown 'refresh'
                        return op!
                catch
                    if e.code in <[ nomatch keyempty ]>
                        dd.dropdown 'restore defaults'
                        @set \item, {}
                        return op!
                    else
                        throw e
            external-change := no

        set-item = (value-of-key) ~>
            if @get \data
                data = that
                if @get \multiple
                    items = []
                    selected-keys = []
                    selected-names = []
                    for val in value-of-key when val
                        if find (.[keyField] is val), data
                            items.push that
                            selected-keys.push that[keyField]
                            selected-names.push that[nameField]
                            if @get \debug => @actor.c-log "Found #{val} in .[#{keyField}]", that[keyField]
                        else
                            # how can't we find the item?
                            debugger
                    if @get \debug => debugger
                    @set \item, unless empty items => items else [{}]
                    @set \selected-name, selected-names
                    @set \selected-key, selected-keys
                    @fire \select, {}, (unless empty items => items else [{}])
                else
                    # set a single value
                    if find (.[keyField] is value-of-key), data
                        selected = that
                        if @get('selected-key') isnt that[keyField]
                            if @get \debug => @actor.c-log "selected key is changed to:", selected[keyField]
                            if @get \debug => @actor.c-log "Found #{value-of-key} in .[#{keyField}]", selected, selected[keyField]
                            if @get \async
                                @fire \select, c, selected, (err) ~>
                                    unless err
                                        @set \emptyReduced, no
                                        update-dropdown selected[keyField]
                                    else
                                        curr = @get \selected-key
                                        @actor.c-err "Error reported for dropdown callback: ", err,
                                            "falling back to #{curr}"
                                        @set \emptyReduced, yes
                                        update-dropdown curr
                            else
                                @set \selected-key, selected[keyField]

                        unless @get \async
                            @set \item, selected
                            @set \selected-name, selected[nameField]
        dd
            .dropdown 'restore defaults'
            .dropdown 'setting', do
                forceSelection: no
                #allow-additions: @get \allow-additions ## DO NOT SET THIS; SEMANTICS' NOT UX FRIENDLY
                full-text-search: (text) ~>
                    @set \search-term, text
                    data = @get \data
                    if text
                        #@actor.c-log "Dropdown (#{@_guid}) : searching for #{text}..."
                        result = @get \sifter .search asciifold(text), do
                            fields: @get \search-fields
                            sort: [{field: nameField, direction: 'asc'}]
                            nesting: no
                            conjunction: "and"
                        reduced = [data[..id] for small-part-of(result.items)]
                        @set \dataReduced, reduced
                        if empty reduced
                            @actor.log.err "No such item found: #{text}"
                        @set \emptyReduced, empty reduced

                        #@actor.c-log "Dropdown (#{@_guid}) : data reduced: ", [..id for @get \dataReduced]
                    else
                        #@actor.c-log "Dropdown (#{@_guid}) : searchTerm is empty"
                        @set \dataReduced, small-part-of data
                on-change: (value, text, selected) ~>
                    return if external-change
                    if @get \debug => @actor.c-log "Dropdown: #{@_guid}: dropdown is changed: ", value
                    if @get \multiple
                        set-item unless value? => [] else value.split ','
                    else
                        set-item value
                    @set \dataReduced, small-part-of @get \data

        @observe \data, (data) ~>
            if @get \debug => @actor.c-log "Dropdown (#{@_guid}): data is changed: ", data
            <~ set-immediate
            if data and not empty data
                @set \loading, no
                @set \dataReduced, small-part-of data
                @set \sifter, new Sifter(data)
                # Update dropdown visually when data is updated
                selected-handler @get \selected-key
                @set \emptyReduced, false
            else
                @set \emptyReduced, true

        selected-handler = (_new, old) ~>
            if @get \multiple
                if typeof! _new is \Array
                    if JSON.stringify(_new or []) isnt JSON.stringify(old or [])
                        update-dropdown _new
            else
                if @get \debug => @actor.c-log "Observe: selected key set to:", _new
                #@actor.c-log "DROPDOWN: selected key set to:", _new
                unless @get \data
                    #@actor.c-warn "...but returning as there is no data yet."
                    return
                update-dropdown _new

        @observe \selected-key, selected-handler

        @on do
            teardown: ->
                dd.dropdown 'destroy'

            '_add': (ctx) ->
                c.button = ctx.component
                sleep 10, -> dd.dropdown 'show'
                err <~ @fire \add, c, @get \search-term
                # dropdown should only be closed if there is
                # no error returned
                unless err
                    dd.dropdown 'hide'
                    @set \emptyReduced, false
                    @set \search-term, ''
                    # fixme: clear the dropdown text
                    #dd.dropdown 'set text', 'aaa'

    data: ->
        'allow-addition': no
        'search-fields': <[ id name description ]>
        'search-term': ''
        data: undefined
        dataReduced: []
        keyField: \id
        nameField: \name
        nothingSelected: '---'
        item: {}
        loading: no
        'start-with-loading': no
        sifter: null
        nomatch: false

        # this is very important. if you omit this, "selected"
        # variable will be bound to class prototype (thus shared
        # across the instances)
        'selected-key': null
        'selected-name': null
        'load-first': 100
