from losoto.h5parm import h5parm
import sys
import numpy as np
from astropy.stats import sigma_clip
from numpy.ma import median
from scipy.signal import savgol_filter
from scipy.stats import median_abs_deviation, circstd, binned_statistic
from scipy.signal import correlate
from tqdm import tqdm

h5name = sys.argv[1]
# h5name = "cal_solutions.h5"

#h5 = h5parm(h5name, readonly=False)
h5 = h5parm(h5name, readonly=True)
ss = h5.getSolset("target")
st = ss.getSoltab("TGSSphase_final")

metadata = st.getValues()[1]
t = metadata["time"]

refant = metadata["ant"][0]

phases_ref = st.getValues(refAnt="CS007HBA1")[0]
phases_ref = np.transpose(phases_ref, (0, 3, 2, 1))
#phases_ref = phases - phases[:, :, :, 12, None]
phases_ref_diff = (phases_ref[:, 0, :, :] - phases_ref[:, 1, :, :] + np.pi) % (2*np.pi) - np.pi
print(phases_ref_diff.shape)


# assert phases.shape[-1] == 2, "Polarisation axis is not last or has more than 2 polarisations."
#phases_poldif = phases[..., 0] - phases[..., -1]

s = []
c = sum(["CS" in ant for ant in metadata["ant"]])
has_cs = np.char.find(metadata["ant"], "CS") >= 0

phases_ref_diff[~np.isfinite(phases_ref_diff)] = 0
pd_filtered = savgol_filter(sigma_clip(phases_ref_diff, sigma=4, masked=True, axis=0), 59, 2, axis=0)
mask = np.isfinite(pd_filtered)
pd_filtered_cs = pd_filtered[:, :, np.where(has_cs)]

s = []
for ant in np.where(has_cs)[0]:
    data = phases_ref_diff[:, 0, ant]
    data[~np.isfinite(data)] = 0

    pd_filtered = savgol_filter(sigma_clip(data, sigma=4, masked=True), 59, 2)
    mask = np.isfinite(pd_filtered)
    pd_filtered = np.interp(t, t[mask], pd_filtered[mask])

    s.append(circstd(data))


mean_scatter = np.average(s)
median_scatter = np.median(s)
print(f"{mean_scatter=}, {median_scatter=}")

import matplotlib.pyplot as plt

pbar_chan = tqdm(total=len(metadata["freq"]))
pbar_ant = tqdm(total=len(metadata["ant"]))
for channel in range(len(metadata["freq"])):
    pbar_chan.update()
    fig, ax = plt.subplots(8, 8, figsize=(16,9), dpi=600)
    axes = np.ravel(ax)
    i = 0
    for station in metadata["ant"]:
        pbar_ant.update()
        if "CS" not in station and "RS" not in station:
            continue
        idx = np.argwhere(metadata["ant"] == station)
        #phasediff = (
        #    (phases_ref[:, 0, channel, idx] - phases_ref[:, 1, channel, idx]).squeeze()
        #    + np.pi
        #) % (2 * np.pi) - np.pi
        phasediff = phases_ref_diff[:, channel, idx].squeeze()

        phasediff[~np.isfinite(phasediff)] = 0
        t = metadata["time"]
        bins = len(phasediff) // 8 + 1
        binned_std, _, _ = binned_statistic(
            t, phasediff, statistic=circstd, bins=bins
        )
        bstd_full = np.repeat(binned_std, 8)[: len(phasediff)]
        axes[i].scatter(metadata["time"], phasediff, color="b", marker=".", s=1)

        mask_bad_timeslot = bstd_full > median_scatter
        phasediff[mask_bad_timeslot] = np.nan
        axes[i].scatter(metadata["time"], phasediff, color="r", marker=".", s=1)
        axes[i].set_ylim(-1, 1)
        axes[i].axhline(median_scatter, color="k")
        axes[i].text(0.5, 0.9, station, ha="center", va="center_baseline", transform=axes[i].transAxes)
        axes[i].xaxis.set_visible(False)
        axes[i].yaxis.set_visible(False)
        i += 1
        #phases[mask_bad_timeslot, :, channel, idx] = np.nan
    fig.savefig(f"test_channel{channel:04d}.png", bbox_inches="tight", dpi=300)
    plt.close(fig)
    pbar_ant.reset()

#st.setValues(phases.transpose((0,3,2,1)))
h5.close()
