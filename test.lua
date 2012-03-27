arr = {x = 1}
arr2 = {2,7,4,3}

function table.find(l, e) -- find element v of l satisfying f(v)
    for i, v in ipairs(l) do
        if v == e then
            return i
        end
    end
    return -1
end

function test()
    local a = arr
    a.x = 30
end

test()
print(table.find({}, 7))
