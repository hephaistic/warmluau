local warmluau = require("@warmluau/")
local append_comment = require("@warmluau/ingredients/append_comment")

warmluau.bake(
    append_comment.prepare({
        text = "-- cooked with warmluau\n"
    })
)
