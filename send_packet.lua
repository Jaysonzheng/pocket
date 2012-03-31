function broadcast_game_will_start(game_room)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_START_GAME);
	packet.write_byte(game_room.dealer_seatid);
    packet.write_int(game_room.basechip)
    packet.write_int(game_room.playing_count)
    for i=1, MAX_PLAYER_COUNT do
        if game_room.playing_users[i] ~= 0 then
            local game_seat = game_seat_table[game_room.roomid][i]
            packet.write_int(game_seat.money)
            packet.write_int(game_seat.round_chip)
        end
    end
	packet.write_end();
    broadcast_room_packet(game_room)
end

function broadcast_user_bet(game_room, seatid, chip)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_USER_BET)
    packet.write_short(seatid)
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_user_fold(game_room, user)
    debug("玩家弃牌, seatid = " .. user.seatid)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_USER_FOLD)
    packet.write_short(user.seatid)
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_user_check(game_room, user)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_USER_CHECK)
    packet.write_short(user.seatid)
    packet.write_end()
    broadcast_room_packet(game_room)
end


function broadcast_next_chip(game_room, next_seat)
    local seat = game_seat_table[game_room.roomid][next_seat]

    local need_chip = game_room.round_highest_money - seat.round_chip
    debug("下一位下注玩家："..next_seat .. ", 需要至少下注 " .. need_chip .. ", 可下注钱数 ".. seat.money)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_NEXT_CHIP)
    packet.write_short(next_seat)
    packet.write_int(game_room.round_highest_money)
    packet.write_int(need_chip)
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_flop(game_room)
    debug("start round flop")
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_FLOP)
    packet.write_short(game_room.public_cards[1])
    packet.write_short(game_room.public_cards[2])
    packet.write_short(game_room.public_cards[3])
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_turn(game_room)
    debug("start round turn")
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_TURN)
    packet.write_short(game_room.public_cards[4])
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_river(game_room)
    debug("start round river")
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_RIVER)
    packet.write_short(game_room.public_cards[5])
    packet.write_end()
    broadcast_room_packet(game_room)
end

function broadcast_game_over(game_room)
    packet.write_begin(PROTOCAL.SERVER_COMMAND_BC_STOP_GAME)
    packet.write_end()
    broadcast_room_packet(game_room)
end

-- broadcast room packet
function broadcast_room_packet(game_room)
    -- broadcast playing users
    for i=1, MAX_PLAYER_COUNT do
        local userid = game_room.playing_users[i]
        if userid ~= 0 then
            local user = game_user_table[userid]
            packet.send_package(user.socket)
        end
    end
   
    -- broadcast waiting users
    for i=1, #game_room.waiting_users do
        local userid = game_room.waiting_users[i][1]
        local user = game_user_table[userid]
        packet.send_package(user.socket)
    end
    
    -- broadcast onlooking users
    for i=1, #game_room.onlooking_users do
        local user = game_user_table[game_room.onlooking_users[i]]
        packet.send_package(user.socket)
    end
end

function send_deal_card(roomid, seatid, card1, card2)
    debug("deal card, seat:" .. seatid .. ",card1:{" ..card1[1] ..","..card1[2].."}, card2:{" .. card2[1] ..", "..card2[2].."}")
end

