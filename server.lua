-- 初始化服务器
function handle_init()
	print("server init")

    --table.foreach(global_command_args, function(i, v) print (i, v) end) 
    --table.foreach(test_arr, function(i, v) print (i, v) end) 

--    fd = client.connect_server("192.168.100.30", 4019,  false, 1)
--    print("fd = "..fd)
--    package.send_buffer(fd, "hello my world")	
--    package.write_begin(0x504)
--    package.write_string("127.0.0.1")
--    package.write_int(1235)
--    package.write_short(2)
--    package.write_end()
--    package.send_raw_packet(fd)
--    
--    local port = global_command_args["p"]
--    server.create_listener(port)

    mysql.connect_mysql("192.168.100.30", "root", "", "dice", 3306)

    len = table.getn(global_result_set) 
    print("table.len="..len)
    for i=1, len do
        t = global_result_set[i]
        len2 = table.getn(t)
        print(len2)
        for j=1, len2 do
            print(t[j])
        end
        print("\n")
    ena
    global_result_set = nil
    return 0
end

-- 停止服务器
function handle_fini()
	
end

-- 处理数据包
function handle_input(fd, buffer, length)
	print("recv buffer: "..buffer)
	--package.send_buffer(fd, "hello my world")	
end

-- 远程服务器断开连接
function handle_server_socket_close(socket, conn_type)
	print("remote server socket has closed")

end

-- 客户端断开连接
function handle_client_socket_close(socket)
	print("client socket has closed----")
end
