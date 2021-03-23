function switch(statement)
    return function(expressions)
        return (expressions[statement] or expressions.default or function() return nil end)()
    end
end

return switch -- for the love of god dont make this a loadstring smh
