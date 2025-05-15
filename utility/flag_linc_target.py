import argparse
import sys

import numpy as np
from losoto.h5parm import h5parm
from scipy.signal import medfilt
from scipy.stats import binned_statistic, circstd
from tqdm import tqdm

h5name = sys.argv[1]


class LINCTargetFlagger:
    def __init__(self, h5name: str, solset: str, soltab: str):
        """Initialise a solution flagger.

        Args:
            h5name (str): name of the h5parm to be flagged.
            solset (str): name of the solset containing the soltab to be flagged.
            soltab (str): name of the soltab containing the solutions to be flagged.
        """
        self.h5 = h5parm(h5name, readonly=False)
        self.ss = self.h5.getSolset(solset)
        self.st = self.ss.getSoltab(soltab)

        self.metadata = self.st.getValues()[1]
        self.t = self.metadata["time"]
        self.ants = self.metadata["ant"]

        self.refant = self.metadata["ant"][0]

    def load_weights(self):
        print("[BEGIN] loading weights")
        self.weights = self.st.getValues(weight=True)[0]
        print("[END] loading weights")

    def load_wrapped_phases(self):
        print("[BEGIN] loading phases")
        self.phases_ref = self.st.getValues(refAnt="CS007HBA1")[0]
        self.phases_ref = np.transpose(self.phases_ref, (0, 3, 2, 1))
        self.phases_ref_diff = (
            self.phases_ref[:, 1, :, :] - self.phases_ref[:, 0, :, :] + np.pi
        ) % (2 * np.pi) - np.pi
        print("[END] loading phases")

    def get_core_scatter(self):
        has_cs = np.char.find(self.ants, "CS") >= 0
        s = []
        for ant in np.where(has_cs)[0]:
            data = self.phases_ref_diff[:, 0, ant]
            data[~np.isfinite(data)] = 0
            pd_filtered = medfilt(data, 59)
            print(f"Scatter for antenna {ant} is {circstd(data-pd_filtered)}")
            s.append(circstd(data - pd_filtered))
        return s

    def flag_solutions(self, blank_data: bool):
        """Flag bad phase solutions.

        Args:
            blank_data (bool): whether to set the phases to NaN (True) or just set the weights to 0 (False).
        """
        print("[BEGIN] flagging solutions")
        s = self.get_core_scatter()
        mean_scatter = np.average(s)
        median_scatter = np.median(s)
        print(f"{mean_scatter=}, {median_scatter=}")

        pbar_ant = tqdm(total=len(self.metadata["ant"]))
        pbar_chan = tqdm(total=len(self.metadata["freq"]))
        for station in self.metadata["ant"]:
            pbar_ant.update()
            for channel in range(len(self.metadata["freq"])):
                pbar_chan.update()
                if "CS" not in station and "RS" not in station:
                    continue
                idx = np.argwhere(self.metadata["ant"] == station)
                phasediff = self.phases_ref_diff[:, channel, idx].squeeze()

                phasediff[~np.isfinite(phasediff)] = 0
                t = self.metadata["time"]
                bins = len(phasediff) // 8 + 1
                binned_std, _, _ = binned_statistic(
                    t, phasediff, statistic=circstd, bins=bins
                )
                bstd_full = np.repeat(binned_std, 8)[: len(phasediff)]

                mask_bad_timeslot = bstd_full > 3 * median_scatter
                self.phases_ref[mask_bad_timeslot] = np.nan
                self.weights[mask_bad_timeslot] = 0.0
            pbar_chan.reset()
        if blank_data:
            self.st.setValues(self.phases_ref)
        self.st.setValues(self.weights, weight=True)
        self.h5.close()
        print("[END] flagging solutions")


def main():
    parser = argparse.ArgumentParser(
        description="Flag bad regions in LINC target diagonal phase solutions."
    )
    parser.add_argument("--h5parm", type=str, help="H5parm that will be flagged.")
    parser.add_argument(
        "--solset",
        type=str,
        help="Solset containing the target solutions.",
        default="target",
    )
    parser.add_argument(
        "--soltab",
        type=str,
        help="Soltab containing diagonal phase solutoins to flag.",
        default="TGSSphase_final",
    )
    parser.add_argument(
        "--sigma",
        type=float,
        default=3.0,
        help="Flag time bins for which circstd(XX-YY) exceeds this multiple of the reference value.",
    )
    parser.add_argument(
        "--blank-data",
        action="store_true",
        help="Also set data to NaN in addition to setting weights to 0.",
    )
    args = parser.parse_args()

    flagger = LINCTargetFlagger(args.h5parm, args.solset, args.soltab)
    flagger.load_weights()
    flagger.load_wrapped_phases()
    flagger.flag_solutions(args.blank_data)


main()
