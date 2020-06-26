from shakenfist.client import apiclient

from shakenfist_ci import base


class TestSystemNamespace(base.BaseTestCase):
    def test_system_namespace(self):
        self.assertEqual('system', self.system_client.namespace)
