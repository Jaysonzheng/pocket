require("packet")
require("send_packet")
require("common")
require("card")

game_room_table = {}    -- 房间表
game_seat_table = {}    -- 座位表
socket_mid_table = {}	-- socket fd map表，key为socket fd，value为mid
game_user_table = {}    -- 用户表


MAX_PLAYER_COUNT = 9 
DEBUG = 1
GAME_STATUS = 
{
    "GAME_STATUS_STOP",
    "GAME_STATUS_STARTGAME",
    "GAME_STATUS_PRE_FLOP",
    "GAME_STATUS_FLOP",
    "GAME_STATUS_TURN",
    "GAME_STATUS_RIVER",
}

PROTOCAL = 
{
    SERVER_COMMAND_BC_START_GAME,
    SERVER_COMMAND_BC_USER_BET,
    SERVER_COMMAND_BC_USER_CALL,
    SERVER_COMMAND_BC_USER_CHECK,
    SERVER_COMMAND_BC_USER_FOLD,
    SERVER_COMMAND_BC_NEXT_CHIP,
    SERVER_COMMAND_BC_FLOP,
    SERVER_COMMAND_BC_TURN,
    SERVER_COMMAND_BC_RIVER,
    
}

GAME_STATUS = CreatEnumTable(GAME_STATUS)

function debug(msg, ...)
    if DEBUG == 1 then
        print(msg, ...)
    end 
end

function dump_user_data(userid)
    local user = game_user_table[userid]
    if user == nil then
        debug("user is not found, userid = " .. userid)
        return 
    end

    for k, v in pairs(user) do
        debug(k .. "=" ..v)
    end
    debug("")
end

function dump_room_data_by_id(roomid)
	local room = game_room_table[roomid]
	if room == nil then 
		print("room not exist roomid = "..roomid)
		return 
	end
    dump_room_data(room)
end

function dump_room_data(room)
    print("\n=======start dump_room_data=========")
    print("roomid: " .. room.roomid)
    print("basechip: " .. room.basechip)
    print("requirechip: " .. room.requirechip)
    print("dealer_seatid: " .. room.dealer_seatid)
    print("cur_op_seat: " .. room.cur_op_seat)
    print("round_highest_money: " .. room.round_highest_money)
    print("round_total_money: " .. room.round_total_money)
    print("main_pot: " .. room.main_pot)
    
    local str = "{"
    print("public_cards: ")
    for i = 1, #room.public_cards do
        str = str .."{".. room.public_cards[i][1] .. "," ..room.public_cards[i][2] .. "}, "
    end
    str = str .."}"
    print("public_cards: " .. str)

    local str = "{"
    print("playing_count: " .. room.playing_count)
    for i = 1, #room.playing_users do
        str = str .. room.playing_users[i] .. ", "
    end
    str = str .."}"
    print("playing_users: " .. str)

    str = "{"
    for i=1, #room.waiting_users do
        str = str .. "{" .. room.waiting_users[i][1] .. ", " .. room.waiting_users[i][2] .. "}, "
    end
    str = str .. "}"
    print("waiting_users: " .. str)

    str = "{"
    for i=1, #room.onlooking_users do
        str = str .. room.onlooking_users[i] 
        if i < #room.onlooking_users then 
           str = str .. ", "
        end
    end
    str = str .. "}"
    print("onlooking_users: " .. str)

    str = "{"
    for i=1, #room.round_op_users_list do
        str = str .. room.round_op_users_list[i] 
        if i < #room.round_op_users_list then 
           str = str .. ", "
        end
    end
    str = str .. "}"
    print("round_op_users_list: " .. str)

    print("=======end dump_room_data=========\n")
end

function dump_chip_list(room)
    str = "{"
    for i=1, #room.round_op_users_list do
        str = str .. room.round_op_users_list[i] 
        if i < #room.round_op_users_list then 
           str = str .. ", "
        end
    end
    str = str .. "}"
    print("round_op_users_list: " .. str)
    
end

function printtable(t)
for i,v in pairs(t) do
   if type(v) == "table" then
    printtable(v);
   else
    print(i.." = "..tostring(v));
   end  
end
end

function init_room(in_roomid, in_basechip, in_requirechip)
    local room = 
    {
        roomid = in_roomid,
        basechip = in_basechip,
        requirechip = in_requirechip,
        dealer_seatid = 0,
    
        playing_count = 0,
        playing_users = {0, 0, 0, 0, 0, 0, 0, 0, 0}, --正在玩的玩家
        waiting_users = {},         --等待下一局开始的玩家
        onlooking_users = {},       --旁观玩家
        cur_op_seat = 1,

        round_highest_money = 0,
        round_total_money = 0,
    
        round_op_users_list = {},
        public_cards = {},
        status = GAME_STATUS.GAME_STATUS_STOP,

        main_pot = 0,
        all_in_users = {},
    }
    game_room_table[in_roomid] = room
   
    game_seat_table[in_roomid] = {}
    -- seat list
    for i=1, MAX_PLAYER_COUNT do
        game_seat_table[in_roomid][i] = 
        {
            card1 = nil,
            card2 = nil,
            card_type = {0}, 
            money = 0,
            round_chip = 0,
            side_pot = 0,
            pot_users = {},
            is_allin = false,
        }  
    end

end

function init_user(in_userid, in_socket, in_money, in_roomid)
   game_user_table[in_userid] = 
   {
        userid = in_userid,
   	    socket = in_socket,
        money  = in_money,
        roomid = in_roomid,
        seatid = 0,   
   }
   socket_mid_table[in_socket] = in_userid
end

function on_user_join(in_socket, in_userid, in_roomid)
    if game_room_table[in_roomid] == nil then
        init_room(in_roomid, 100, 1000)
    end

    init_user(in_userid, in_socket, 6000, in_roomid)
    table.insert(game_room_table[in_roomid].onlooking_users, in_userid)
end

function on_user_leave(uid)
    local user = game_user_table[userid]

    if user.seatid ~= 0 then
        
    end
    game_user_table[userid] = nil
    game_room_table[user.roomid] = nil
end

function on_user_sit(in_socket, seatid, buy_money)
    local room, user = get_user_data_by_socket(in_socket)
 
    if user.money < room.requirechip then 
        debug("user have not enough money")
        return -1
    end
    
--    if buy_money < room.basechip*40 then
--        buy_money = room.basechip*40
--    end
    if buy_money > room.basechip*200 then 
        buy_money = room.basechip*200
    end
   
    if buy_money >= user.money then
        debug("user have not enough money, buy_money = ".. buy_money .. ", user money = ".. user.money)
        return -1
    end

    if room.status == GAME_STATUS.GAME_STATUS_STOP then 
        room.playing_users[seatid] = user.userid
        room.playing_count = room.playing_count + 1
    else
        table.insert(room.waiting_users, {user.userid, seatid})
    end

    user.seatid = seatid
    game_seat_table[room.roomid][seatid].money = buy_money
    
    debug("user sit, userid = " .. user.userid .. ", seatid = " .. seatid)
    if room.status == GAME_STATUS.GAME_STATUS_STOP and room.playing_count >= 3 then --游戏还没开始，够两个人可以开始了
        start_game(room.roomid)
    end   

    return 0
end

function on_user_stand(in_socket)
    local room, user = get_user_data_by_socket(in_socket)
    
    return 0
end

function on_user_bet(in_socket, chip)
    local room, user = get_user_data_by_socket(in_socket)
    return user_bet(room.roomid, user.seatid, chip)
end

function on_user_call(in_socket)
    local room, user = get_user_data_by_socket(in_socket)
    local seat = game_seat_table[user.roomid][user.seatid]

    -- 跟注,当前回合最大下注数
    return user_bet(room.roomid, user.seatid, room.round_highest_money - seat.round_chip)
end

function on_user_check(in_socket)
    local room, user = get_user_data_by_socket(in_socket)
    local seat = game_seat_table[user.roomid][user.seatid]

    if check_user_op_valid(room.roomid, user.seatid) == false then 
        return -1
    end
    
    if room.round_highest_money - seat.round_chip> 0 then
        debug("user can not check")
        return -1
    end
    
    room.cur_op_seat = get_next_seat(room, user.seatid)
    game_room_table[room.roomid] = room
    
    broadcast_user_check(room, user)

    local next_seat = get_next_chip_seat(room)
    if next_seat == nil then -- 
        start_next_round(room)
    else
        broadcast_next_chip(room, next_seat)
    end

    return 0
end

function on_user_fold(in_socket)
    local room, user = get_user_data_by_socket(in_socket)
    if check_user_op_valid(room.roomid, user.seatid) == false then
        return -1
    end
 
    --加到等待队列中，从在玩的列表中删除
    room.playing_users[user.seatid] = 0
    local wait_user = {user.userid, user.seatid}
    table.insert(room.waiting_users, wait_user)
    room.playing_count = room.playing_count - 1

--    debug("user fold, seatid = " .. user.seatid)
--    dump_chip_list(room)
    
    broadcast_user_fold(room, user)
    local next_seat = get_next_chip_seat(room)
    if next_seat == nil then -- next chip user
        start_next_round(room)
    else
        --debug("next chip seat:" .. next_seat)
        room.cur_op_seat = next_seat
        broadcast_next_chip(room, next_seat)
    end
    game_room_table[room.roomid] = room

    return 0
end

function check_user_op_valid(roomid, seatid)
    if game_room_table[roomid].status == GAME_STATUS.GAME_STATUS_STOP
        or game_room_table[roomid].cur_op_seat ~= seatid then 
        debug("check user operation failed" .. game_room_table[roomid].cur_op_seat .. seatid)
        return false
    end
    return true
end

function start_game(roomid)
    local room = game_room_table[roomid]
    next_dealer(roomid)

    -- 等待玩家进入玩牌玩家列表
    for i=1, #room.waiting_users do 
        local userid = room.waiting_users[i][1]
        local seatid = room.waiting_users[i][2]
        room.playing_users[seatid] = userid
    end

    local poker_cards = init_card()
    local card1, card2, card3, card4, card5, rest_cards
    card1, rest_cards = deal_card(poker_cards)
    card2, rest_cards = deal_card(rest_cards)
    card3, rest_cards = deal_card(rest_cards)
    card4, rest_cards = deal_card(rest_cards)
    card5, rest_cards = deal_card(rest_cards)
    room.public_cards = {card1, card2, card3, card4, card5}
    
    room.waiting_users = {}
    room.playing_count = 0 
    -- deal card
    for i = 1, MAX_PLAYER_COUNT do 
        local userid = room.playing_users[i]
        if userid ~= 0 then
            card1, rest_cards = deal_card(rest_cards)
            card2, rest_cards = deal_card(rest_cards)
            game_seat_table[roomid][i].card1 = card1
            game_seat_table[roomid][i].card2 = card2
            --debug(card1[1],card1[2], card2[1], card2[2])
            send_deal_card(roomid, i, card1, card2)
            room.playing_count = room.playing_count + 1
        end
    end
    
    local smallblind_seat = get_next_seat(room, room.dealer_seatid)
    game_seat_table[roomid][smallblind_seat].round_chip = room.basechip
    local tmp_money = game_seat_table[roomid][smallblind_seat].money 
    game_seat_table[roomid][smallblind_seat].money = tmp_money - room.basechip
    local smallblind_userid = game_user_table[room.playing_users[smallblind_seat]].userid
    game_user_table[smallblind_userid].money = game_user_table[smallblind_userid].money - room.basechip

    local bigblind_seat = get_next_seat(room, smallblind_seat)
    game_seat_table[roomid][bigblind_seat].round_chip = room.basechip*2
    tmp_money = game_seat_table[roomid][bigblind_seat].money 
    game_seat_table[roomid][bigblind_seat].money = tmp_money - room.basechip*2
    local bigblind_userid = game_user_table[room.playing_users[bigblind_seat]].userid
    game_user_table[bigblind_userid].money = game_user_table[bigblind_userid].money - room.basechip*2
    
    -- first chip user
    room.round_highest_money = room.basechip*2
    room.round_total_money = room.basechip*3
    room.status = GAME_STATUS.GAME_STATUS_PRE_FLOP
    
    -- bet seat list
    for i=0, MAX_PLAYER_COUNT-1 do
        local next_seat = room.cur_op_seat + i
        if next_seat > MAX_PLAYER_COUNT then 
            next_seat = next_seat-MAX_PLAYER_COUNT
        end
        if room.playing_users[next_seat] ~= 0 then
            table.insert(room.round_op_users_list, next_seat)
        end
    end

    local cur_chip_seat = get_next_chip_seat(room)  
    room.cur_op_seat = cur_chip_seat
    
    print(string.format("start game, smallblind = %d, bigblind = %d, dealer seat = %d", room.basechip, room.basechip*2, room.dealer_seatid))
    broadcast_game_will_start(room)
    broadcast_next_chip(room, room.cur_op_seat)
end

function start_next_round(room)
    if room.playing_count == 1 then -- only one player left, he wins
        debug("one player left, game over")
        for i=1, MAX_PLAYER_COUNT do
            local userid = room.playing_users[i]
            if userid ~= 0 then
                local user = game_user_table[userid]
                user.money = user.money + room.main_pot
                game_user_table[userid] = user
                debug("user money = " .. user.money)
                return 0
            end
        end
    end    

--    room.main_pot = room.main_pot + room.round_total_money
    room.status = room.status + 1
    room.round_total_money = 0
    room.round_highest_money = 0
    room.cur_op_seat = get_next_seat(room, room.dealer_seatid)

    room.round_op_users_list = {}
    for i=1, MAX_PLAYER_COUNT-1 do
        local next_seat = room.dealer_seatid + i
        if next_seat > MAX_PLAYER_COUNT then 
            next_seat = next_seat - MAX_PLAYER_COUNT
        end
        if room.playing_users[next_seat] ~= 0 and game_seat_table[room.roomid][next_seat].money > 0 then
            table.insert(room.round_op_users_list, next_seat)
        end
    end
    
    -- bet user list
    local bet_chip_list = {}
    local is_have_allin_user = false
    local game_round_chip = 0

    for i=1, MAX_PLAYER_COUNT do
        local seat = game_seat_table[room.roomid][i]
        if seat.round_chip ~= 0 then
            game_round_chip = game_round_chip + seat.round_chip
            
            table.insert(bet_chip_list, {i, seat.is_allin, seat.round_chip})
            if seat.is_allin == true then 
                is_have_allin_user = true
            end
        end
    end
    
    if is_have_allin_user == false then
        room.main_pot = room.main_pot + game_round_chip
    else 
        local sortFunc = function(a, b) 
            if a[2] == true and b[2] == false then  -- 按玩家的下注数排序，all in的在前面 
                return true
            elseif a[2] == false and b[2] == true then
                return false
            elseif a[2] == true and b[2] == true then
                return a[3] < b[3]
            end
            return false
        end
        table.sort(bet_chip_list, sortFunc)
--      for i=1, #bet_chip_list do 
--          print(bet_chip_list[i][1], bet_chip_list[i][2], bet_chip_list[i][3])
--      end
   
        --all in user
        --对于all in 的玩家，计算奖池
        local chip_user_count = #bet_chip_list
        for i=1, chip_user_count-1 do
            local firstseatid = bet_chip_list[i][1]
            local firstseat = game_seat_table[room.roomid][firstseatid]
            local bet_chip = bet_chip_list[i][3]

            local pot = 0
            local is_allin = bet_chip_list[i][2]
            if is_allin == true then 
                table.insert(room.all_in_users, i)
            end

            for j=i, chip_user_count do
                local seatid = bet_chip_list[j][1]  
                local seat = game_seat_table[room.roomid][seatid]
                seat.round_chip = seat.round_chip - bet_chip
                bet_chip_list[j][3] = bet_chip_list[j][3] - bet_chip
                --debug(i,chip_user_count, seatid, seat.round_chip)
            
                table.insert(firstseat.pot_users, bet_chip_list[j][1])
                pot = pot + bet_chip
            end
            pot = room.main_pot + pot
            room.main_pot = 0 
            firstseat.side_pot = pot
--            for k=1, #firstseat.pot_users do
--                debug(firstseatid .. " pot user:" .. "" .. firstseat.pot_users[k])
--            end
        end
    end

    for i=1, MAX_PLAYER_COUNT do
        game_seat_table[room.roomid][i].round_chip = 0
    end
    
    -- at least playing_count-1 all in, stop game
    if #room.all_in_users >= room.playing_count - 1 then
        debug("user all in, stop game")
        stop_game(room)
        return 0
    end

    if room.status == GAME_STATUS.GAME_STATUS_FLOP then
        broadcast_flop(room)
    elseif room.status == GAME_STATUS.GAME_STATUS_TURN then
        broadcast_turn(room)
    elseif room.status == GAME_STATUS.GAME_STATUS_RIVER then
        broadcast_river(room)
    else
        --debug("unkown status, some error")
        debug("game over")
        stop_game(room)
        return 0
    end
     
    debug("start_next_round, status = " .. room.status)
    broadcast_next_chip(room, room.cur_op_seat)
    return 0
end

function stop_game(room)
    local seat_card_type = {}
    for i=1, MAX_PLAYER_COUNT do
        local userid = room.playing_users[i]
        if userid ~= 0 then
            seat = game_seat_table[room.roomid][i]
            seat.card_type = get_card_type({seat.card1, seat.card2}, room.public_cards)
            --game_seat_table[room.roomid][i] = seat

            table.insert(seat_card_type, {i, game_seat_table[room.roomid][i].card_type}) 
        end
    end

    local sortFunc = function(a, b) 
        if a[2][1] == b[2][1] then  --牌型相同，就比点数
            for i=2, 6 do
                if a[2][i][2] ~= b[2][i][2] then
                    if a[2][i][2] > b[2][i][2] then 
                        return true
                    end
                    --elseif b[2][i][2] > a[2][i][2] then 
                    return false
                    
                end
            end
        end
        return a[2][1] > b[2][1]
    end

    table.sort(seat_card_type, sortFunc)
    game_room_table[room.roomid] = room
    debug("game over, winner seatid = " .. seat_card_type[1][1])

    -- calc winner seat
    local win_seats= {}
    for i=1, MAX_PLAYER_COUNT do 
        win_seats[i] = {}
    end
    local pos = 1
    for i=1, #seat_card_type-1 do
        local first_seatid = seat_card_type[i][1]
        local first_card_type = seat_card_type[i][2][1]
        local sec_seatid = seat_card_type[i+1][1]
        local sec_card_type = seat_card_type[i+1][2][1]
        
        --牌型一样，比大小
        if first_card_type == sec_card_type then
            local flag = false
            for j=2, 6 do
                if seat_card_type[i][2][j][2] > seat_card_type[i+1][2][j][2] then 
                    if table.find(win_seats[pos], first_seatid) == -1 then
                        table.insert(win_seats[pos], first_seatid)
                    end
                    flag = true
                    break
                end
            end
            if flag == true then
                pos = pos+1
            else 
                -- 所有的牌都一样，牌型一样
                if table.find(win_seats[pos], first_seatid) == -1 then 
                    table.insert(win_seats[pos], first_seatid)
                end
                if table.find(win_seats[pos], sec_seatid) == -1 then 
                    table.insert(win_seats[pos], sec_seatid)
                end
            end
        else 
            if table.find(win_seats[pos], first_seatid) == -1 then
                table.insert(win_seats[pos], first_seatid)
            end
            pos = pos + 1
        end
    end
    
    -- 该局没有all in 玩家，只有一个主池
    -- 如果有all in的，需要遍历每个玩家，在每位玩家奖池内的玩家列表中取最高牌将该奖池分给赢家
    --
    if #room.all_in_users == 0 then
        -- get money 
        local admire_money = room.main_pot / #win_seats[1]
        for i=1, #win_seats do
            local userid = room.playing_users[win_seats[i]]
            local user = game_user_table[userid]
            user.money = user.money + admire_money
        end
    else 
        for i=1, MAX_PLAYER_COUNT do
            local seat = game_seat_table[room.roomid][i]
            if #seat.pot_users ~= 0 then 
                --calc who win the pot 
                local pot_users = seat.pot_users
                local pot_win_users = {}
                for j=1, pos do
                    local tmp_seats = win_seats[j]
                    for l=1, #tmp_seats do

                        --debug("pot user", win_seats[j][l], tmp_seats[1])
                        if table.find(pot_users, win_seats[j][l]) ~= -1 then
                            --debug("----pot user", win_seats[j][l], #tmp_seats)
                            table.insert(pot_win_users, win_seats[j][l])
                        end    
                    end
                    if #pot_win_users == true then
                        break
                    end
--                    for k=1, #pot_users do 
--                        debug(pot_users[j])
--                    end

                    if #pot_win_users ~= 0 then 
                        break
                    end
                end
                debug(i, seat.side_pot, #pot_win_users, #win_seats)

                -- pot
                local pot_win_count = #pot_win_users
                for j=1, pot_win_count do 
                    local admire_money = seat.side_pot / pot_win_count
                    local userid = room.playing_users[pot_win_users[j]]
                    --debug(j, userid, pot_win_users[j])
                    local user = game_user_table[userid]
                    user.money = user.money + admire_money
                end
 
            end
        end
    end
    -- log
    for i=1, #seat_card_type do
        local seatid = seat_card_type[i][1]
        local card_type = seat_card_type[i][2][1]
        local str = "seat:".. seatid ..", card type = " .. card_type .. ", best cards:{"
        for j=2, 6 do
            str = str .. "{" .. seat_card_type[i][2][j][1] .. "," .. seat_card_type[i][2][j][2] .. "}" 
        end
        str = str .. "}"
        print("seat_card_type: " .. str)
    end

    broadcast_game_over(room)
end

function next_dealer(roomid)
    local room = game_room_table[roomid]   
    for i = 1, MAX_PLAYER_COUNT do 
        local seatid = (room.dealer_seatid+i) % MAX_PLAYER_COUNT 
        if room.playing_users[seatid] ~= 0 then
            room.dealer_seatid = seatid
            game_room_table[roomid] = room
            break
        end
    end
end

function get_next_seat(room, seatid)
    for i = 1, MAX_PLAYER_COUNT-1 do
        local next_seat = seatid + i
        if next_seat > MAX_PLAYER_COUNT then 
            next_seat = next_seat-MAX_PLAYER_COUNT
        end
        if room.playing_users[next_seat] ~= 0 then    --该座位不空
            return next_seat
        end       
    end
    return seatid
end

function get_next_chip_seat(room)
    local seatid = table.remove(room.round_op_users_list, 1)
    return seatid
end

function get_user_data_by_socket(in_socket)
    local uid = socket_mid_table[in_socket]
    local roomid = game_user_table[uid].roomid
    local room = game_room_table[roomid]
    local user = game_user_table[uid]
    return room, user
end

function user_bet(roomid, seatid, chip)
    if check_user_op_valid(roomid, seatid) == false then
        return -1
    end
    
    local seat = game_seat_table[roomid][seatid]
    if seat.money - chip <= 0 then 
        debug("user all in, user's money = " .. seat.money .. ", chip = "..chip)
        seat.money = 0
        seat.is_allin = true
    end

    local room = game_room_table[roomid]
    local userid = room.playing_users[seatid]
    local user = game_user_table[userid]

    seat.round_chip = seat.round_chip + chip
    seat.money = seat.money - chip

    user.money = user.money - chip
    room.round_total_money = room.round_total_money + chip
   
    -- check if user raise
    if room.round_highest_money < seat.round_chip  then 
        room.round_highest_money = seat.round_chip
        
        debug("user raise, seatid = " .. seatid .. ", chips = " .. room.round_highest_money .. ", room round chips = " .. room.round_total_money)
        -- 重新排队下注玩家顺序列表
        room.round_op_users_list = {}
        for i = 1, MAX_PLAYER_COUNT-1 do 
            local next_seat = seatid + i
            if next_seat > MAX_PLAYER_COUNT then 
                next_seat = next_seat - MAX_PLAYER_COUNT
            end
            
            --该座位不空且有钱
            if room.playing_users[next_seat] ~= 0 and game_seat_table[roomid][next_seat].money > 0 then               
                table.insert(room.round_op_users_list, next_seat)
            end 
        end
    else 
        debug("user call, seatid = " .. seatid ..", room round chips = ".. room.round_total_money)
    end

    broadcast_user_bet(room, seatid, room.round_highest_money)
       
    dump_chip_list(room)
    local next_seat = get_next_chip_seat(room)
    if next_seat == nil then -- next chip user
        start_next_round(room)
    else
        --debug("next chip seat: " .. next_seat)
        game_room_table[room.roomid].cur_op_seat = next_seat
        broadcast_next_chip(room, next_seat)
    end
  
    return 0
end

function test_join_and_sit()
    --join game room
    on_user_join(1, 1, 1)
    on_user_join(2, 2, 1)
    on_user_join(3, 3, 1)

    --user sit down
    assert(on_user_sit(1, 1, 1000) == 0) 
    assert(on_user_sit(2, 6, 1200) == 0)
    assert(on_user_sit(3, 8, 1500) == 0)

end

function test_call()
    assert(on_user_call(1) == 0)

    assert(on_user_bet(2, 400) == 0)
    assert(on_user_call(3) == 0)
    assert(on_user_call(1) == 0)
    --assert(on_user_fold(1) == 0)
    --dump_room_data_by_id(1)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_call(3) == 0)
    assert(on_user_call(1) == 0)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_call(3) == 0)
    assert(on_user_call(1) == 0)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_call(3) == 0)
    assert(on_user_call(1) == 0)
    
    dump_room_data_by_id(1)
    dump_user_data(1)
    dump_user_data(2)
    dump_user_data(3)
end

function test_fold()
    assert(on_user_call(1) == 0)

    assert(on_user_bet(2, 400) == 0)
    assert(on_user_call(3) == 0)
    assert(on_user_call(1) == 0)
    
    assert(on_user_bet(2, 100) == 0)
    assert(on_user_fold(3) == 0)
    assert(on_user_fold(1) == 0)

    dump_room_data_by_id(1)
    dump_user_data(1)
    dump_user_data(2)
    dump_user_data(3)
end

function test_allin()
    assert(on_user_call(1) == 0)
--    assert(on_user_bet(2,1100) == 0)
    assert(on_user_fold(2) == 0)
    assert(on_user_bet(3,1000) == 0)
    assert(on_user_bet(1,800) == 0)
    dump_room_data_by_id(1)
    dump_user_data(1)
    dump_user_data(2)
    dump_user_data(3)

end

test_join_and_sit()
--test_call()
test_allin()

--bet_chip_list = {{1, true, 300}, {2, true, 200}, {3, true, 400}, {4, false, 400}}
--    local sortFunc = function(a, b) 
--        if a[2] == true and b[2] == false then
--            return true
--        elseif a[2] == false and b[2] == true then
--            return false
--        elseif a[2] == true and b[2] == true then
--            return a[3] < b[3]
--        end
--        return false
--    end
--table.sort(bet_chip_list, sortFunc)

--for i=1, #bet_chip_list do 
--    print(bet_chip_list[i][1], bet_chip_list[i][2], bet_chip_list[i][3])
--end
-- 
--    local chip_user_count = #bet_chip_list
--    for i=1, chip_user_count do 
--        local bet = bet_chip_list[i][3]
--        local pot = 0
--        for j=i, chip_user_count do
--            if bet_chip_list[j][2] == true then 
--                bet_chip_list[j][3] = bet_chip_list[j][3] - bet
--                pot = pot + bet
--                print(i, j, pot)
--            else 
--                bet_chip_list[j][3] = bet_chip_list[j][3] - bet
--                pot = pot + bet
--                print(i, j, pot)
--            end
--        end
--        print(pot)
--    end

