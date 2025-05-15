import sys

import numpy as np
from losoto.h5parm import h5parm
from scipy.signal import medfilt
from scipy.stats import binned_statistic, circstd
from tqdm import tqdm

h5name = sys.argv[1]

h5 = h5parm(h5name, readonly=True)
ss = h5.getSolset("target")
st = ss.getSoltab("TGSSphase_final")

metadata = st.getValues()[1]
t = metadata["time"]

refant = metadata["ant"][0]

phases_ref = st.getValues(refAnt="CS007HBA1")[0]
weights = st.getValues(weight=True)[0]
phases_ref = np.transpose(phases_ref, (0, 3, 2, 1))
phases_ref_diff = (phases_ref[:, 1, :, :] - phases_ref[:, 0, :, :] + np.pi) % (
    2 * np.pi
) - np.pi

ants = metadata["ant"]

def get_core_scatter():
    has_cs = np.char.find(metadata["ant"], "CS") >= 0
    s = []
    for ant in np.where(has_cs)[0]:
        data = phases_ref_diff[:, 0, ant]
        data[~np.isfinite(data)] = 0
        pd_filtered = medfilt(data, 59)
        print(f"Scatter for antenna {ant} is {circstd(data-pd_filtered)}")
        s.append(circstd(data - pd_filtered))
    return s


s = get_core_scatter()

mean_scatter = np.average(s)
median_scatter = np.median(s)
print(f"{mean_scatter=}, {median_scatter=}")

BLANK_DATA = False


def main():
    pbar_ant = tqdm(total=len(metadata["ant"]))
    pbar_chan = tqdm(total=len(metadata["freq"]))
    for station in metadata["ant"]:
        pbar_ant.update()
        for channel in range(len(metadata["freq"])):
            pbar_chan.update()
            if "CS" not in station and "RS" not in station:
                continue
            idx = np.argwhere(metadata["ant"] == station)
            phasediff = phases_ref_diff[:, channel, idx].squeeze()

            phasediff[~np.isfinite(phasediff)] = 0
            t = metadata["time"]
            bins = len(phasediff) // 8 + 1
            binned_std, _, _ = binned_statistic(
                t, phasediff, statistic=circstd, bins=bins
            )
            bstd_full = np.repeat(binned_std, 8)[: len(phasediff)]

            mask_bad_timeslot = bstd_full > 3 * median_scatter
            phases_ref[mask_bad_timeslot] = np.nan
            weights[mask_bad_timeslot] = 0.0
        pbar_chan.reset()
    if BLANK_DATA:
        st.setValues(phases_ref)
    st.setValues(weights, weight=True)
    h5.close()


main()
