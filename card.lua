require("common")

--10.royal flush
--9.straight flush
--8.four of a kind
--7.full house
--6.flush
--5.straight
--4.three of a kind
--3.two pairs
--2.one pairs
--1.high card
--
--

CARD_TYPE = 
{
    "HIGH_CARD",
    "ONE_PAIR",
    "TWO_PAIRS",
    "THREE_OF_A_KIND",
    "STRAIGHT",
    "FLUSH",
    "FULL_HOUSE",
    "FOUR_OF_A_KIND",
    "STRAIGHT_FLUSH",
    "ROYAL_FLUSH",
}

CARD_TYPE = CreatEnumTable(CARD_TYPE)

local check_straight_flush, check_four_kind, check_flush, check_three, check_pairs, check_straight, get_flush

--
function init_card()
    local poker = {}
    for i=1, 4 do
        for j=1, 13 do
            table.insert(poker, {i, j})
        end
    end
    return poker
end

function deal_card(cardlist)
    math.randomseed(os.time()) math.random()  
    cardnum = math.random(1,#cardlist)
    result = cardlist[cardnum]  
    table.remove(cardlist,cardnum) 
    --print(string.format("%x, %x", result[1], result[2]))
    return result, cardlist
end

function get_card_type(cardlist)
    local check_funcs = {check_straight_flush, check_four_kind, check_three, check_flush, check_straight, check_pairs}
    local func_count =  #check_funcs
    for i=1, func_count do
        local result = check_funcs[i](cardlist)
        if result ~= 0 then
            return result
        end
    end

    local result = check_straight_flush(cardlist)
    if result ~= 0 then
        return result 
    end
    
    return 0
end

function compare_card(cardlist1, cardlist2)
    local type1 = get_card_type(cardlist1)
    local type2 = get_card_type(cardlist2)
    if type1[1] == type2[1] then        --相同牌型
        if type1 == CARD_TYPE.FLUSH then
            return 0
        end

        for i=2, 6 do
            if type1[i][2] ~= type2[i][2] then
                if type1[i][2] > type2[i][2] then 
                    return 1
                elseif type1[i][2] < type2[i][2] then 
                    return -1
                end
            end
        end
        return 0
    else    --不同牌型
        if type1[1] > type2[1] then 
            return 1
        else 
            return -1
        end
    end
end

function sort_card(cardlist)
    local sortFunc = function(a, b) 
        if a[2] == b[2] then
            return b[1] < a[1]
        end
        return b[2] < a[2]
    end 
    table.sort(cardlist, sortFunc)
    return cardlist
end

function check_straight_flush(cardlist)
    local result = get_flush(cardlist)
    if result == 0 then
        return 0
    else
        local len = #result
        local count = 0
        for i=2, len - 4 do
            local flag = true
            for j=0, 3 do
                --print(i, j, result[i+j][2], result[i+j+1][2] )
                if result[i+j][2] ~= result[i+j+1][2] + 1 then
                    flag = false
                    break
                end
            end
            if flag == true then 
                local finalcards = {CARD_TYPE.STRAIGHT_FLUSH}
                if result[i][2] == 13 then
                    finalcards = {CARD_TYPE.ROYAL_FLUSH}
                end
                for k=i, i+4 do
                    table.insert(finalcards, result[k])
                end
                return finalcards
            end
        end
        return 0 
    end
end

function check_four_kind(cardlist)
    local len = #cardlist
    for i=1, 4 do
        if  cardlist[i][2] == cardlist[i+1][2] and
            cardlist[i][2] == cardlist[i+2][2] and
            cardlist[i][2] == cardlist[i+3][2] then 
            for j=1, len do
                if cardlist[j][2] ~= cardlist[i][2] then
                    local finalcards = {CARD_TYPE.FOUR_OF_A_KIND, cardlist[i], cardlist[i+1], cardlist[i+2], cardlist[i+3], cardlist[j]}
                    return finalcards
                end
            end
        end
    end
    return 0
end

function check_flush(cardlist)
    local len = #cardlist
    local finalcards = {}
    for i=1, 4 do
        local count = 0
        for j=1, len do
            if cardlist[j][1] == i then
                count = count+1
                table.insert(finalcards, cardlist[j])
                --print(cardlist[j])
                if count >= 5 then
                    table.insert(finalcards, 1, CARD_TYPE.FLUSH)
                    return finalcards
                end
            end
        end
        finalcards = {}
    end
    return 0
end

function get_flush(cardlist)
    local len = #cardlist
    local finalcards = {}
    for i=1, 4 do
        local count = 0
        for j=1, len do
            if cardlist[j][1] == i then
                count = count+1
                table.insert(finalcards, cardlist[j])
            end
        end
        if count >= 5 then
            table.insert(finalcards, 1, CARD_TYPE.FLUSH)
            return finalcards
        else 
            finalcards = {}
        end
    end
    return 0
end


function check_three(cardlist)
    local len = #cardlist
    for i=1, 5 do
        if  cardlist[i][2] == cardlist[i+1][2] and
            cardlist[i][2] == cardlist[i+2][2] then
            for j=1, len do
                if cardlist[j][2] ~= cardlist[i][2] then
                    if cardlist[j][2] == cardlist[j+1][2] then -- full house
                        local finalcards = {CARD_TYPE.FULL_HOUSE, cardlist[i], cardlist[i+1], cardlist[i+2], cardlist[j], cardlist[j+1]}
                        return finalcards
                    end
                        
                    for k=j+1, len do -- three of a kind
                        if cardlist[k][2] ~= cardlist[i][2] then
                            local finalcards = {CARD_TYPE.THREE_OF_A_KIND, cardlist[i], cardlist[i+1], cardlist[i+2], cardlist[j], cardlist[k]}
                            return finalcards
                        end
                    end
                end
            end
        end
    end
    return 0
end

function check_pairs(cardlist)
    local len = #cardlist
    local pairs_table = {}
    for i=1, 6 do
        if cardlist[i][2] == cardlist[i+1][2] then
            table.insert(pairs_table, cardlist[i][2])
        end
    end
    
    local finalcards = {}
    if #pairs_table >= 2 then       -- two pairs
        table.insert(finalcards, CARD_TYPE.TWO_PAIRS)
        local p = 1
        for i=1, 6 do   
            if cardlist[i][2] == pairs_table[p] then
                table.insert(finalcards, cardlist[i])
                table.insert(finalcards, cardlist[i+1])
                i = i+2
                p = p+1
                if p >2 then break end
            end    
        end
        for i=1, len do
            if cardlist[i][2] ~= pairs_table[1] and cardlist[i][2] ~= pairs_table[2] then
                table.insert(finalcards, cardlist[i])
                return finalcards
            end
        end   
    elseif #pairs_table == 1 then   -- one pairs
        table.insert(finalcards, CARD_TYPE.ONE_PAIR)
        for i=1, 6 do   
            if cardlist[i][2] == pairs_table[1] then
                table.insert(finalcards, cardlist[i])
                table.insert(finalcards, cardlist[i+1])
                break
            end    
        end
        local count = 0
        for i=1, len do
            if cardlist[i][2] ~= pairs_table[1] then
                table.insert(finalcards, cardlist[i])
                count = count + 1
                if count >= 3 then
                    return finalcards 
                end
            end
        end   
    else
        return {1, cardlist[1], cardlist[2], cardlist[3], cardlist[4], cardlist[5]}
    end
end


function check_straight(cardlist)
    local len = #cardlist
    for i=1, 3 do
        local finalcards = {cardlist[i]}
        for j=i+1, len do
            if cardlist[j][2] == finalcards[#finalcards][2] - 1 then 
                table.insert(finalcards, cardlist[j]) 
                if #finalcards >= 5 then
                    table.insert(finalcards, 1, CARD_TYPE.STRAIGHT)
                    return finalcards
                end
            end
        end
    end
    return 0
end

function test()

    card = init_card()
    deal_card(card)
    card = sort_card({{2,4}, {1, 3}, {3, 8}, {2, 3}, {2, 8}})
    for i=1, #card do
        print(card[i][1], card[i][2])
    end

    local result = check_flush({{1,3}, {1, 4}, {1, 6}, {1, 7}, {2, 8}, {2, 4}, {3, 6}})
    print(result)

    --assert(check_four_kind({{3,5}, {2,4}, {1,4}, {4,3}, {3,3}, {2,3}, {1,3}}) == { {4,3}, {3,3}, {2,3}, {1,3}, {3,5}})
    result = check_four_kind({{3,5}, {2,4}, {1,4}, {4,3}, {3,3}, {2,3}, {1,3}})

    result = check_three({{3,5}, {2,5}, {1,5}, {4,3}, {3,3}, {2,2}, {1,2}})   -- full house
    result = check_three({{3,10}, {3,5}, {2,5}, {1,5}, {3,3}, {2,2}, {1,2}})  -- three of a kind

    result = check_pairs({{3,5}, {2,5}, {1,4}, {4,3}, {3,3}, {2,2}, {1,2}})  -- two pairs 
    result = check_pairs({{3,10}, {2,9}, {1,9}, {4,5}, {3,4}, {2,3}, {1,2}}) -- one pair

    result = check_flush({{3,10},{3,9},{3,8},{3,7},{3,6},{3,5},{2,4}})
    --result = check_straight_flush({{3,10},{3,9},{4,8},{3,8},{3,7},{4,6},{3,6},{3,5}})

    result = get_card_type({{3,11},{3,9},{4,8},{3,8},{3,7},{4,6},{3,6},{3,5}})
    --assert(result == {{3,9},{4,8},{3,7},{4,6},{3,5}})
    if result  == 0 then
        print("result = false")
    end

    print("check result :" .. result[1])
    for i=2, #result do
        print(result[i][1], result[i][2])
    end

    get_card_type({{3,11},{3,9},{4,8},{3,8},{3,7},{4,6},{3,6},{3,5}})

end

function unit_test()
    assert(get_card_type({{3,13}, {3,12},{3,11},{3,10},{3,9},{4,6},{3,8}})[1] == CARD_TYPE.ROYAL_FLUSH)
    assert(get_card_type({{4,13}, {4,12},{3,12},{2,12},{1,12},{4,6},{3,8}})[1] == CARD_TYPE.FOUR_OF_A_KIND)
    assert(get_card_type({{3,11},{3,9},{4,8},{3,8},{3,7},{4,6},{3,6},{3,5}})[1] == CARD_TYPE.STRAIGHT_FLUSH)
    assert(get_card_type({{3,5}, {2,5}, {1,5}, {4,3}, {3,3}, {2,2}, {1,2}})[1] == CARD_TYPE.FULL_HOUSE)
    assert(get_card_type({{3,5}, {2,5}, {1,5}, {4,4}, {3,3}, {2,2}, {1,1}})[1] == CARD_TYPE.THREE_OF_A_KIND)
    assert(check_flush({{4,11}, {3,11}, {4,10}, {4,9}, {4,8}, {3,7}, {4,5}})[1] == CARD_TYPE.FLUSH)
    assert(get_card_type({{4,11}, {3,11}, {4,10}, {4,9}, {4,8}, {3,7}, {3,5}})[1] == CARD_TYPE.STRAIGHT)
    assert(get_card_type({{4,11}, {3,11}, {3,8}, {2,8}, {4,5}, {1,4}, {2,3}})[1] == CARD_TYPE.TWO_PAIRS)
    assert(get_card_type({{4,12}, {3,11}, {3,8}, {2,8}, {4,5}, {1,4}, {2,3}})[1] == CARD_TYPE.ONE_PAIR)
    assert(get_card_type({{4,13}, {3,11}, {3,9}, {2,8}, {4,5}, {1,4}, {2,3}})[1] == CARD_TYPE.HIGH_CARD)
   
    local cardlist1 = {{3,13}, {3,12},{3,11},{3,10},{3,9},{4,6},{3,8}}
    local cardlist2 = {{4,13}, {4,12},{3,12},{2,12},{1,12},{4,6},{3,8}}
    assert(compare_card(cardlist1, cardlist2) == 1)

    cardlist1 = {{4,13}, {3,13},{2,13},{1,13},{3,9},{4,6},{3,8}}
    cardlist2 = {{4,13}, {4,12},{3,12},{2,12},{1,12},{4,6},{3,8}}
    assert(compare_card(cardlist1, cardlist2) == 1)

    cardlist1 = {{4,10}, {3,9},{2,8},{1,7},{3,6},{2,6},{3,2}}
    cardlist2 = {{3,9},{2,8},{1,7},{3,6},{2,6},{3,5}, {3,2}}
    assert(compare_card(cardlist1, cardlist2) == 1)


    print("all tests pass")

end
unit_test()
