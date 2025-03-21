import random
import matplotlib.pyplot as plt


class MTB:

    # Initializer / Instance attributes
    def __init__(
        self,
            deadtime=1,
            prescale=1.0,
    ):

        self.DEADTIME = deadtime
        self.prescale = prescale
        self.tick = 0
        self.deadcnt = 0

    # Instance method
    def clk(self):

        # bump the tick
        self.tick += 1

        # drop the deadtime
        if self.deadcnt > 0:
            self.deadcnt -= 1

    # Instance method
    def try_to_trigger(self):
        if (self.deadcnt > 0 or random.uniform(0, 1) >= self.prescale):
            return False
        else:
            self.deadcnt = self.DEADTIME
            return True


class Generator:

    # Initializer / Instance attributes
    def __init__(
        self,
        rate=1000,  # kHz
    ):
        self.p = rate/100000

    def trigger(self):

        if random.uniform(0, 1) <= self.p:
            return True
        else:
            return False


if __name__ == '__main__':

    sim_time = 1000000

    n_points = 20
    x = [p / n_points for p in range(n_points)]
    y = [0.0] * n_points

    gen = Generator()

    for i, prescale in enumerate(x):

        accept = 0
        reject = 0
        generated = 0

        mtb = MTB(prescale=prescale)

        for _ in range(sim_time):
            if gen.trigger():
                t = mtb.try_to_trigger()
                generated += 1
                accept += t
                reject += not t
                mtb.clk()

        gen_rate = generated/sim_time/10*1000000
        accept_rate = accept/sim_time/10*1000000
        y[i] = accept_rate
        print(f'prescale={prescale} gen_rate={gen_rate:0.0f} {accept=} {reject=}')

    plt.plot(x, y)
    plt.show()
