require 'socket'

# ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-linux]

# socket の host と http の host では socket の方が低レイヤーなので、socket の host の方が優先されるのは当たり前
# 間違った、もしくは不正な host で socket を作成しても常に SocketError が発生するとは限らない
  # socket の host の方は DNS か何かで補完されるみたいなので、一文字間違っていても期待した http response が返ってきてしまう
# http の host が不正な場合は、socket で指定した host がどんな http status を返すかを決めるので、一定の値は返ってこない

# TCPSocket オブジェクトを生成する過程で名前解決を行っている。
  # TCPSocket は IPSocket を継承しており、TCPSocket のオブジェクトを生成する過程で IPSocket.getaddress を実行している。
    # TCPSocket は initialize に失敗した場合(名前解決に失敗した場合) SocketError を返す
    # IPSocket.getaddress は名前解決に失敗した場合に SocketError を返す
# 名前解決に失敗して SocketError が発生するはず。
  # 期待通り(SocketError が発生する)
    # 'hoge'
      # `initialize': getaddrinfo: Temporary failure in name resolution (SocketError)
      # ping
        # ping: hoge: Temporary failure in name resolution
    # 'www.hoge.co'
      # `initialize': getaddrinfo: Temporary failure in name resolution (SocketError)
      # ping
        # ping: www.hoge.co: Temporary failure in name resolution
    # 'www.google.c
      # `initialize': getaddrinfo: Name or service not known (SocketError)
      # ping
        # ping: www.google.c: Name or service not known
  # 期待通りではない。(SocketError が発生しない。)
    # 'www.hogehoge.com'
      # ping
        # PING hogehoge.com (219.94.128.220) 56(84) bytes of data.
        # 64 bytes from www980.sakura.ne.jp (219.94.128.220): icmp_seq=1 ttl=49 time=51.9 ms
        # さくらインターネットのサーバが存在した
    # 'www.hoge.com'
      # ping
        # PING hoge.wpengine.com (104.197.1.13) 56(84) bytes of data.
        # 64 bytes from 13.1.197.104.bc.googleusercontent.com (104.197.1.13): icmp_seq=1 ttl=44 time=225 ms
        # google が保有する何かしらのサーバが存在するみたい
    # 'www.googl.co'
      # ping
        # PING www.googl.co (185.53.177.50) 56(84) bytes of data.
        # 名前解決には成功しているみたいだが、よくわからない
    # 'www.google.co'
      # ping
        # PING www.googl.co (185.53.177.50) 56(84) bytes of data.
        # 名前解決には成功しているみたいだが、よくわからない
    # 'www.googl.com'
      # ping
        # PING www.googl.com (172.217.174.99) 56(84) bytes of data.
        # 64 bytes from nrt12s28-in-f3.1e100.net (172.217.174.99): icmp_seq=1 ttl=109 time=78.8 ms
        # 名前解決には成功しているみたいだが、よくわからない
    # 'www.goog.com'
      # ping
        # PING www.goog.com (162.144.156.107) 56(84) bytes of data.
        # 64 bytes from server.fvg.uib.mybluehost.me (162.144.156.107): icmp_seq=1 ttl=45 time=283 ms
        # 名前解決には成功しているみたいだが、よくわからない
# 名前解決に成功して SocketError は発生しないはず。
  # 期待通り。(SocketError が発生しない。)
    # 'www.google.com'

socket = TCPSocket.new('www.google.com', 80)

# socket に header を書き込むことで、request が送られる
# 全ての request で header の Host に www.google.com を指定した
  # 'www.hogehoge.com' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.hogehoge.com_header_www.google.com.txt
      # HTTP/1.1 403 Forbidden
      # さくらインターネットから response が返ってきた
  # 'www.hoge.com' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.hoge.com_header_www.google.com.txt
      # HTTP/1.1 404 Not Found
      # hoge.wpengine.com から response が返ってきてるみたい
  # 'www.googl.co' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.googl.com_header_www.google.com.txt
      # HTTP/1.1 403 Forbidden
      # よくわからない
  # 'www.google.co' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.google.com_header_www.google.com.txt
      # HTTP/1.0 200 OK
      # google.com から response が返ってきた
        # '.com' 部分は '.co' となっていても補完されて connection は確立するのかもしれない
  # 'www.googl.com' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.googl.com_header_www.google.com.txt
      # HTTP/1.0 200 OK
      # google.com から response が返ってきたい
        # サブドメインは1文字間違っていても補完されて connection は確立するのかもしれない
  # 'www.goog.com' で socket を作成した場合
    # tcpsocket/responses/invalid_socket/socket_www.goog.com_header_www.google.com.txt
      # HTTP/1.1 200 OK
      # よくわからないところから response が返ってきた
        # サブドメインは2文字間違っていると補完されないみたい

# 全ての socket を 'www.google.com' で作成した
  # header に www.hogehoge.com を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.hogehoge.com.txt
      # HTTP/1.0 404 Not Found
      # google から response が返ってきた
        # google と さくらインターネットで http status が異なっている
          # 逆の値を入れていた時は 403 が返ってきていた
  # header に www.hoge.com を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.hoge.com.txt
      # HTTP/1.0 404 Not Found
      # google から response が返ってきた
  # header に www.googl.co を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.googl.co.txt
      # HTTP/1.0 404 Not Found
      # google から response が返ってきた
  # header に www.google.co を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.google.co.txt
      # HTTP/1.0 301 Moved Permanently
      # google から response が返ってきた
        # 404 or 200 が返ってくると思ってたけど、301 だった。
          # よくわからない
  # header に www.googl.com を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.googl.com.txt
      # HTTP/1.0 301 Moved Permanently
      # google から response が返ってきた
        # 404 or 200 が返ってくると思ってたけど、301 だった。
          # よくわからない
  # header に www.goog.com を指定した場合
    # tcpsocket/responses/invalid_host/socket_www.google.com_header_www.goog.com.txt
      # HTTP/1.0 404 Not Found
      # google から response が返ってきた
        # 上2つは 301 なのに、なぜ 404 なのかよくわからない

socket.write "GET / HTTP/1.0\r\nAccept: */*\r\nConnection: close\r\nHost: www.goog.com\r\n\r\n"

puts socket.read

socket.close
