#!/usr/bin/env python3
import sys
import base64
import json
token = sys.argv[1]
parts = token.split('.')

class Part:
    def __init__(self, data):
        self.data = data

    def __repr__(self):
        return json.dumps(self.data, indent='  ', sort_keys=True)

def decode(part):
    base64_message = part + '==='
    base64_bytes = base64_message.encode('ascii')
    message_bytes = base64.b64decode(base64_bytes)
    message = message_bytes.decode('ascii')
    data = json.loads(message)
    return Part(data)
    return json.dumps(data, indent='  ', sort_keys=True)


print('header:')
print(decode(parts[0]))
print()

print('payload (claims):')
claims = decode(parts[1])
print(claims)
scope = claims.data.get('scope')
if scope:
    print('scope:\n-', '\n- '.join(scope.split()))
print()

print('signature (b64):')
print(parts[2])
