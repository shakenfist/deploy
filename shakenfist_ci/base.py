import random
import string
import sys
import testtools
import telnetlib
import time


from shakenfist.client import apiclient


class BaseTestCase(testtools.TestCase):
    def setUp(self):
        super(BaseTestCase, self).setUp()

        self.system_client = apiclient.Client()

    def _make_namespace(self, name, key):
        self._remove_namespace(name)

        self.system_client.create_namespace(name, 'test', key)
        return apiclient.Client(
            base_url=self.system_client.base_url,
            namespace=name,
            key=key)

    def _remove_namespace(self, name):
        ns = self.system_client.get_namespaces()
        if name in ns:
            self.system_client.delete_namespace(name)

    def _uniquifier(self):
        return ''.join(random.choice(string.ascii_lowercase) for i in range(8))


class LoggingSocket(object):
    ctrlc = '\x03'

    def __init__(self, host, port):
        self.s = telnetlib.Telnet(host, port, 30)

    def await_login_prompt(self):
        start_time = time.time()
        while True:
            for line in self.recv().split('\n'):
                if line.rstrip('\r\n ').endswith(' login:'):
                    return

            time.sleep(0.5)
            if time.time() - start_time > 120.0:
                return

    def ensure_fresh(self):
        for d in [self.ctrlc, self.ctrlc, '\nexit\n', 'cirros\n', 'gocubsgo\n']:
            self.send(d)
            time.sleep(0.5)
            self.recv()

    def send(self, data):
        # print('>> %s' % data.replace('\n', '\\n').replace('\r', '\\r'))
        self.s.write(data.encode('ascii'))

    def recv(self):
        data = self.s.read_eager().decode('ascii')
        # for line in data.split('\n'):
        #    print('<< %s' % line.replace('\n', '\\n').replace('\r', '\\r'))
        return data

    def execute(self, cmd):
        self.ensure_fresh()
        self.send(cmd + '\n')
        time.sleep(5)
        d = ''
        while not d.endswith('\n$ '):
            d += self.recv()
        return d
