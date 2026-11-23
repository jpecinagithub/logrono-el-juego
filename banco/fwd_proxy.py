import os, socket, threading, base64
from urllib.parse import urlparse

UP = urlparse(os.environ.get("https_proxy") or os.environ["http_proxy"])
AUTH = "Basic " + base64.b64encode(("%s:%s" % (UP.username, UP.password)).encode()).decode()
HOST, PORT = UP.hostname, UP.port or 3128

def pipe(a, b):
    try:
        while True:
            data = a.recv(65536)
            if not data:
                break
            b.sendall(data)
    except OSError:
        pass
    finally:
        try:
            b.shutdown(socket.SHUT_WR)
        except OSError:
            pass

def handle(client):
    try:
        buf = b""
        while b"\r\n\r\n" not in buf:
            chunk = client.recv(65536)
            if not chunk:
                client.close()
                return
            buf += chunk
        head, rest = buf.split(b"\r\n\r\n", 1)
        lines = head.decode("latin1").split("\r\n")
        method = lines[0].split(" ")[0]
        upstream = socket.create_connection((HOST, PORT), timeout=30)
        if method.upper() == "CONNECT":
            target = lines[0].split(" ")[1]
            req = ("CONNECT %s HTTP/1.1\r\nHost: %s\r\nProxy-Authorization: %s\r\nProxy-Connection: keep-alive\r\n\r\n" % (target, target, AUTH)).encode()
            upstream.sendall(req)
            rbuf = b""
            while b"\r\n\r\n" not in rbuf:
                chunk = upstream.recv(65536)
                if not chunk:
                    break
                rbuf += chunk
            client.sendall(rbuf)
            if rest:
                upstream.sendall(rest)
        else:
            new_lines = [lines[0]] + [l for l in lines[1:] if not l.lower().startswith("proxy-authorization")]
            new_lines.append("Proxy-Authorization: " + AUTH)
            upstream.sendall(("\r\n".join(new_lines) + "\r\n\r\n").encode("latin1") + rest)
        threading.Thread(target=pipe, args=(client, upstream), daemon=True).start()
        pipe(upstream, client)
    except OSError:
        pass
    finally:
        try:
            client.close()
        except OSError:
            pass

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 18080))
srv.listen(50)
print("fwd listo", flush=True)
while True:
    c, _ = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
