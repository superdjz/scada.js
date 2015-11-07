require! {
  '../../modules/aktos-dcs': {
    RactivePartial,
  }
}

RactivePartial!register ->
  console.log "navbar ls is running..."
  $ ".navbar-nav a" .each ->
    console.log "menu anchor is being modified...."
    $ this .data \custom-click, true
    $ this .click (event) ->
      $ ".navbar-collapse" .collapse 'hide'
      console.log "navbar collapsed..."
