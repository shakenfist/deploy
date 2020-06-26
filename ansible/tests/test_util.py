import testtools


from shakenfist.client import apiclient


class UtilTestCase(testtools.TestCase):
    def setUp(self):
        super(UtilTestCase, self).setUp()

    def test_api_auth(self):
        client = apiclient.Client(
            base_url='http://10.1.1.100:13000', namespace='system', key='Ukoh5vie')
