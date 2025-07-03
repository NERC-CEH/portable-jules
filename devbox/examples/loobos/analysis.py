from pathlib import Path

import matplotlib.pyplot as plt
import xarray as xr


here = Path(__file__).parent
data_path = here / "outputs" / "loobos.test.nc"
plot_dir = here / "plots"


def main() -> None:

    assert data_path.exists()
    plot_dir.mkdir(exist_ok=True, parents=True)

    dataset = xr.open_dataset(data_path)
    print(dataset)

    tstar = dataset.tstar.squeeze()
    print(tstar)

    fig, ax = plt.subplots()
    tstar.plot.line(x="time", ax=ax)
    fig.savefig(plot_dir / "tstar.png")

    fig, ax = plt.subplots()
    tstar.to_dataframe().drop(["latitude", "longitude"], axis=1).xs(1, level="tile").rolling(window="24h").mean().plot(ax=ax, label="daily average")
    ax.legend()
    fig.savefig(plot_dir / "tstar_rolling.png")


if __name__ == "__main__":
    main()
