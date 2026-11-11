import random
import unittest

import loadtest


class PercentileTest(unittest.TestCase):
    def test_nearest_rank(self):
        xs = [float(i) for i in range(1, 101)]
        self.assertEqual(loadtest.percentile(xs, 50), 50.0)
        self.assertEqual(loadtest.percentile(xs, 95), 95.0)
        self.assertEqual(loadtest.percentile(xs, 99), 99.0)
        self.assertEqual(loadtest.percentile(xs, 100), 100.0)

    def test_empty_and_single(self):
        self.assertEqual(loadtest.percentile([], 99), 0.0)
        self.assertEqual(loadtest.percentile([7.0], 50), 7.0)


class MixTest(unittest.TestCase):
    def test_pick_covers_every_entry(self):
        rng = random.Random(1)
        seen = {loadtest.pick(rng, loadtest.MIX)[2] for _ in range(5000)}
        self.assertEqual(seen, {entry[2] for entry in loadtest.MIX})


if __name__ == "__main__":
    unittest.main()
