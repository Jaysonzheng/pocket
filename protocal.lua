require "script/game_room"
protocal_define_table = 
{	
	--格式说明:{命令字，参数列表，描述，lua回调函数}
	--MSG_FORMAT = {"cmdtype", "paramlist", "desc", "callback"},	
--[[
	C_LOGIN  = {	-- 登陆房间
				0x1001, 
				"ddss",
				"roomid, uid, mtkey, info", 
				"on_user_login"
			   },	
]]
	C_LOGOUT = {	-- 退出房间
				0x1002, 
				"", 
				"", 
				"on_user_logout"
			   },
    C_SHOT   = {
                0x2011,
                "babb",
                "",
                "on_user_shot"
               },

	C_CHAT   = {	-- 玩家聊天
				0x1003, 
				"%s", 
				"聊天内容", 
				"on_user_chat"
			   }				
	-- ....
	-- ....
}

PROTOCAL_RSP_TABLE = 
{
    SERVER_MSG_OPPONENT_INCOMING = 0x201C,
    SERVER_MSG_OPPONENT_LEAVE = 0x201D,
    SERVER_MSG_LOGIN_SUCCESS = 0x201A,
    SERVER_MSG_LOGIN_ERROR   = 0x3001,

}

function send_loginsuccess2(in_socket, in_roundmoney, in_oppinfo)
	package.writeBegin(0x201A)
	package.writeInt(in_roundmoney)
	package.writeString(in_oppinfo)
	package.writeEnd();
	package.send_packet(in_socket)
end

LOGIN_ERROR = 
{
    ROOM_FULL = 1,
    UNKOWN_ERROR =2,
}

function send_loginerror(in_socket,reason)
--    local login_err_pak = out_package.create()
--    out_package.write_begin(login_err_pak,SERVER_MSG_LOGIN_ERROR)
--    out_package.write_int(reason)
--    out_package.write_end(login_err_pak)
--    socket.send(in_socket,login_err_pak)
	package.writeBegin(SERVER_MSG_LOGIN_ERROR)
	package.writeInt(reason)
	package.writeEnd()
	package.send_packet(in_socket)
end

function send_oppleave_incoming(in_socket,opp_info)
--    local pak = out_package.create()
--    out_package.write_begin(pak,SERVER_MSG_OPPONENT_INCOMING)
--    out_package.write_string(pak,opp_info)
--    out_package.write_end(pak)
--    socket.send(in_socket,pak)
	package.writeBegin(SERVER_MSG_OPPONENT_INCOMING)
	package.writeString(opp_info)
	package.writeEnd()
	package.send_packet(in_socket)
end

function send_oppleave_msg(in_socket)
    local pak = out_package.create()
    out_package.write_begin(pak,SERVER_MSG_OPPONENT_LEAVE)
    out_package.write_end(pak)
    socket.send(in_socket,pak)
end



function send_game_will_start(in_socket)
    local game_start_pak = out_package.create()
end

function broadcast_game_will_start(in_userlist)
    local usersize = #in_userlist
    for i=1,usersize do
        send_game_will_start(in_userlist[i].m_socket)
    end
end

function on_user_login (in_socket, in_roomid, in_uid, in_mtkey, in_userinfo)
    print("calling me on_user_login, uid="..in_uid.." roomid="..in_roomid.."!!!")
	--check and get user info
	log.write_log(-1, "on user login")

    local room_idx = get_game_room(in_roomid)
    local money,exp,level,wintimes,losttimes = 10000,1000,10,100,200
    local result = add_room_user(room_idx,in_uid,in_socket,in_userinfo,money,exp,level,wintimes,losttimes)
    print("the result"..result)
    if result == 0 then
--        local opp_info = get_opponent_info(room_idx,in_uid)
        local opponent = get_opponent(room_idx,in_uid)
        local opp_info = ""
        if opponent ~= nil then
            send_oppleave_incoming(opponent.m_socket,in_userinfo)
            opp_info = opponent.m_info
        end
        print("the opp_info is "..opp_info)
        send_loginsuccess2(in_socket, TABLE_CONF.base_chip,opp_info) 
       	timer.start_timer(0, 1, 3)

		return 0
    elseif result == -2 then
        print("the room has full!")
        send_loginerror(in_socket,ROOM_FULL)
        return -1
    else
        print("unkown error!")
        send_loginerror(in_socket,UNKOWN_ERROR)
        return -1
    end
end

function on_user_logout (in_socket, in_uid)
    print("calling me on_user_logout")
	--check and get user info
	
    local room_idx = get_roomidx_by_uid(in_uid)
    if room_idx ~= -1 then
        local opponent = get_opponent(room_idx, in_uid)
        if opponent ~= nil then
        --send user leave room to opp
            send_oppleave_msg(opponent.m_socket)
        end
        delete_room_user(room_idx, in_uid)
    end
    return 0
end

