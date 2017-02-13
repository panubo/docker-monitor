#!/usr/bin/env python

import json
import socket
import sys

if len(sys.argv) < 4:
    print("Error: Usage <register-result> <client> <name> <output> <status> <ttl>")
    sys.exit(128)

check_client = sys.argv[1]
check_name = sys.argv[2]
check_output = sys.argv[3]
check_status = int(sys.argv[4])
check_ttl = int(sys.argv[5]) if len(sys.argv) > 5 else 90000

# Our result dict
result = dict()
result['source'] = check_client
result['name'] = check_name
result['output'] = check_output
result['status'] = check_status
result['ttl'] = check_ttl

# TCP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 3030)
sock.connect(server_address)
print (json.dumps(result))
socket.sendall(json.dumps(result))
