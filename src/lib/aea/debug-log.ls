# for debugging purposes
st = new Date! .get-time!
export debug-log = (...x) ->
    console.log.apply this, [(new Date! .get-time! - st) + "ms : "]  ++ x

function align-left width, inp
    x = (inp + " " * width).slice 0, width

export get-logger = (src) ->
    (...x) ->
        console.log.apply this, [(new Date! .get-time! - st) + "ms : ", (align-left 15, "#{src}") + ":"] ++ x
