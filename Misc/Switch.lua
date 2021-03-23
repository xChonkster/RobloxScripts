function switch(statement)
    return function(expressions)
        return (expressions[statement] or expressions.default or function() return nil end)()
    end
end
