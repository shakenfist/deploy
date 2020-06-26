import testtools


from shakenfist.client import apiclient


class BaseTestCase(testtools.TestCase):
    def setUp(self):
        super(BaseTestCase, self).setUp()

        self.system_client = apiclient.Client()

    def _make_namespace(self, name, key):
        self._remove_namespace(name)

        self.system_client.create_namespace(name, 'test', key)
        return apiclient(
            base_url=self.system_client.base_url,
            namespace=name,
            key=key)

    def _remove_namespace(self, name):
        ns = self.system_client.get_namespaces()
        if name in ns:
            self.system_client.delete_namespace(name)
