require("packet")
require("send_packet")
require("common")

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
    print("game_money: " .. room.game_money)
    
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
        game_money = 0,
    
        round_op_users_list = {},
        public_cards = {},
        status = GAME_STATUS.GAME_STATUS_STOP,
    }
    
    game_room_table[in_roomid] = room
   
    game_seat_table[in_roomid] = {}
    -- seat list
    for i=1, MAX_PLAYER_COUNT do
        game_seat_table[in_roomid][i] = 
        {
            card1 = nil,
            card2 = nil,
            handtype = nil, 
            money = 0,
            round_chip = 0,
            
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

    init_user(in_userid, in_socket, 1000, in_roomid)
    table.insert(game_room_table[in_roomid].onlooking_users, in_userid)
end

function on_user_leave(uid)
    local user = game_user_table[userid]

    if user.seatid ~= 0 then
        
    end
    game_user_table[userid] = nil
    game_room_table[user.roomid] = nil
end

function on_user_sit(in_socket, seatid)
    local room, user = get_user_data_by_socket(in_socket)
    
    --前面合法性验证
    if room.status == GAME_STATUS.GAME_STATUS_STOP then 
        room.playing_users[seatid] = user.userid
        room.playing_count = room.playing_count + 1

    else
        table.insert(room.waiting_users, {user.userid, seatid})
    end

    user.seatid = seatid
    game_room_table[room.roomid] = room
    game_user_table[user.userid] = user
    game_seat_table[room.roomid][seatid].money = user.money
    
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
    broadcast_user_fold(room, user)
    
    debug("user fold, seatid = " .. user.seatid)
    dump_chip_list(room)
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

    room.waiting_users = {}
    room.playing_count = 0 
    -- deal card
    for i = 1, MAX_PLAYER_COUNT do 
        local userid = room.playing_users[i]
        if userid ~= 0 then
            --deal_card(tid, user.seatid, card1, card2)
            room.playing_count = room.playing_count + 1
        end
    end
    
    local smallblind_seat = get_next_seat(room, room.dealer_seatid)
    game_seat_table[roomid][smallblind_seat].round_chip = room.basechip
    local tmp_money = game_seat_table[roomid][smallblind_seat].money 
    game_seat_table[roomid][smallblind_seat].money = tmp_money - room.basechip*2
    
    local bigblind_seat = get_next_seat(room, smallblind_seat)
    game_seat_table[roomid][bigblind_seat].round_chip = room.basechip*2
    tmp_money = game_seat_table[roomid][bigblind_seat].money 
    game_seat_table[roomid][bigblind_seat].money = tmp_money - room.basechip*2
    
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

    game_room_table[roomid] = room

    print(string.format("start game, smallblind = %d, bigblind = %d, dealer seat = %d", room.basechip, room.basechip*2, room.dealer_seatid))
    broadcast_game_will_start(room)
    broadcast_next_chip(room, room.cur_op_seat)
end

function start_next_round(room)
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
        if room.playing_users[next_seat] ~= 0 then
            table.insert(room.round_op_users_list, next_seat)
        end
    end
    
    game_room_table[room.roomid] = room
    for i=1, MAX_PLAYER_COUNT do
        game_seat_table[room.roomid][i].round_chip = 0
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
        return -1
    end
     
    debug("start_next_round, status = " .. room.status)
    broadcast_next_chip(room, room.cur_op_seat)
    return 0
end

function deal_card(roomid, seatid, card1, card2)
    game_seat_table[roomid][seatid].card1 = card1
    game_seat_table[roomid][seatid].card2 = card2

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
    
    if game_seat_table[roomid][seatid].money - chip <= 0 then 
        debug("user have not enough money, user's money = " ..game_seat_table[roomid][seatid].money .. ", chip = "..chip)
        return -1
    end
    local room = game_room_table[roomid]

    game_seat_table[roomid][seatid].round_chip = game_seat_table[roomid][seatid].round_chip + chip
    local tmp_money = game_seat_table[roomid][seatid].money
    game_seat_table[roomid][seatid].money = tmp_money - chip
    
    tmp_money = room.round_total_money 
    room.round_total_money = tmp_money + chip
    
    -- check if user raise
    if room.round_highest_money < game_seat_table[roomid][seatid].round_chip  then 
        room.round_highest_money = game_seat_table[roomid][seatid].round_chip
        
        debug("user raise, seatid = " .. seatid .. ", chips = " .. room.round_highest_money .. ", room round chips = " .. room.round_total_money)
        -- 重新排队下注玩家顺序列表
        room.round_op_users_list = {}
        for i = 1, MAX_PLAYER_COUNT-1 do 
            local next_seat = seatid + i
            if next_seat > MAX_PLAYER_COUNT then 
                next_seat = next_seat - MAX_PLAYER_COUNT
            end
            if room.playing_users[next_seat] ~= 0 then    --该座位不空
                table.insert(room.round_op_users_list, next_seat)
            end 
        end
    else 
        debug("user call, seatid = " .. seatid ..", room round chips = ".. room.round_total_money)
    end

    game_room_table[roomid] = room
    
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

function test()
    --join game room
    on_user_join(1, 1, 1)
    on_user_join(2, 2, 1)
    on_user_join(3, 3, 1)

    --user sit down
    assert(on_user_sit(1, 1) == 0) 
    assert(on_user_sit(2, 6) == 0)
    assert(on_user_sit(3, 8) == 0)

    assert(on_user_call(1) == 0)
    --assert(on_user_call(2) == 0)
    --assert(on_user_check(3) == 0)

    assert(on_user_bet(2, 400) == 0)
    assert(on_user_call(3) == 0)
    --assert(on_user_call(1) == 0)
    assert(on_user_fold(1) == 0)
    --dump_room_data_by_id(1)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_call(3) == 0)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_call(3) == 0)

    assert(on_user_bet(2, 100) == 0)
    assert(on_user_fold(3) == 0)


end

test()

