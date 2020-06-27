from shakenfist.client import apiclient

from shakenfist_ci import base


class TestSnapshots(base.BaseTestCase):
    def setUp(self):
        super(TestSnapshots, self).setUp()

        self.namespace = 'ci-snapshots-%s' % self._uniquifier()
        self.namespace_key = self._uniquifier()
        self.test_client = self._make_namespace(
            self.namespace, self.namespace_key)

    def tearDown(self):
        super(TestSnapshots, self).tearDown()
        self._remove_namespace(self.namespace)

    def test_snapshots(self):
        net = self.test_client.allocate_network(
            '192.168.242.0/24', True, True, '%s-net' % self.namespace)
        inst = self.test_client.create_instance(
            'cirros', 1, 1,
            [
                {
                    'network_uuid': net['uuid']
                }
            ],
            [
                {
                    'size': 8,
                    'base': 'cirros',
                    'type': 'disk'
                }
            ], None, None)

        self.assertIsNotNone(inst['uuid'])
        self.assertIsNotNone(inst['node'])

        snap1 = self.test_client.snapshot_instance(inst['uuid'])
        self.assertIsNotNone(snap1)

        snap2 = self.test_client.snapshot_instance(inst['uuid'], all=True)
        self.assertIsNotNone(snap2)

        snapshots = self.test_client.get_instance_snapshots(inst['uuid'])
        self.assertEqual({}, snapshots)
