from nose.tools import ok_
from threading import Thread

from unittest import TestCase

from core import EchoPDU
from core.kestrel_mock import KestrelMock

class TestPDU(TestCase):

    def test_echo_pdu_stops_on_signal(self):
        return
        pdu = EchoPDU(queue_system = KestrelMock())
        thread = Thread(target = pdu.run)
        thread.start()
        pdu.stop()
        thread.join(1.0)
        ok_(not thread.is_alive(), "Thread should not be alive!")