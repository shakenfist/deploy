import base64
import time

from oslo_concurrency import processutils
from shakenfist.client import apiclient

from shakenfist_ci import base


class TestStateChanges(base.BaseTestCase):
    def setUp(self):
        super(TestStateChanges, self).setUp()

        self.namespace = 'ci-multinic-%s' % self._uniquifier()
        self.namespace_key = self._uniquifier()
        self.test_client = self._make_namespace(
            self.namespace, self.namespace_key)
        self.net_one = self.test_client.allocate_network(
            '192.168.242.0/24', True, True, '%s-net-one' % self.namespace)
        self.net_two = self.test_client.allocate_network(
            '192.168.243.0/24', True, True, '%s-net-two' % self.namespace)

    def tearDown(self):
        super(TestStateChanges, self).tearDown()
        for inst in self.test_client.get_instances():
            self.test_client.delete_instance(inst['uuid'])
        for net in self.test_client.get_networks():
            self.test_client.delete_network(net['uuid'])
        self._remove_namespace(self.namespace)

    def test_simple(self):
        inst = self.test_client.create_instance(
            'cirros', 1, 1,
            [
                {
                    'network_uuid': self.net_one['uuid']
                },
                {
                    'network_uuid': self.net_two['uuid']
                }
            ],
            [
                {
                    'size': 8,
                    'base': 'cirros',
                    'type': 'disk'
                }
            ], None, None)
        ip = self.test_client.get_instance_interfaces(inst['uuid'])[0]['ipv4']

        self.assertIsNotNone(inst['uuid'])
        self._await_login_prompt(inst['uuid'])

        # Soft reboot
        self.test_client.reboot_instance(inst['uuid'])
        self._await_login_prompt(inst['uuid'])
        self._test_ping(self.net['uuid'], ip)

        # Hard reboot
        self.test_client.reboot_instance(inst['uuid'], hard=True)
        self._await_login_prompt(inst['uuid'])
        self._test_ping(self.net['uuid'], ip)

        # Power off
        self.test_client.power_off_instance(inst['uuid'])
        time.sleep(5)
        self._test_ping(self.net['uuid'], ip, result='0')

        # Power on
        self.test_client.power_on_instance(inst['uuid'])
        self._await_login_prompt(inst['uuid'])
        self._test_ping(self.net['uuid'], ip)

        # Pause
        self.test_client.pause_instance(inst['uuid'])
        time.sleep(5)
        self._test_ping(self.net['uuid'], ip, result='0')

        # Unpause
        self.test_client.unpause_instance(inst['uuid'])
        self._await_login_prompt(inst['uuid'])
        self._test_ping(self.net['uuid'], ip)
