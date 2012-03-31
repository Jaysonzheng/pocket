 
function CreatEnumTable(tbl, index) 
    --assert(IsTable(tbl)) 
    local enumtbl = {} 
    local enumindex = index or 0 
    for i, v in ipairs(tbl) do 
        enumtbl[v] = enumindex + i 
    end 
    return enumtbl 
end 


function table.find(l, e) -- find element v of l satisfying f(v)
    for i, v in ipairs(l) do
        if v == e then
            return i
        end
    end
    return -1
end


