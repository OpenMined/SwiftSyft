# SwiftSyft

## Development

SwiftSyft's library structure was made using `pod lib create`. If you're not familiar with it, you can check out https://guides.cocoapods.org/making/using-pod-lib-create.

## Set-up

You can work on the project by running `pod install` in the root directory. Then open the file `SwiftSyft.xcworkspace` in Xcode. When the project is open on Xcode, you can work on the `SwiftSyft` pod itself in `Pods/Development Pods/SwiftSyft/Classes/*`

The example works by first downloading a training plan from a PyGrid server, running that plan on MNIST data then uploading the model parameter diffs back up to PyGrid.

## PyGrid Setup

Easiest way to get a PyGrid server running on your local computer is to clone the PyGrid Repo then run `docker-compose`

1. `git clone https://github.com/OpenMined/PyGrid.git`
2. `cd` to the PyGrid directory and enter `docker-compose up` on your shell.
3. The `grid-gateway` container will be what we're using and should be running on `127.0.0.1:5000`

If you're having any trouble, try updating `grid-gateway` in `docker-compose.yml` to use `:dev` tag since that tag would hold the latest builds of PyGrid.

## Plan Hosting

The training plan can be created using the notebooks here: https://github.com/OpenMined/PySyft/tree/master/examples/experimental/FL%20Training%20Plan particularly the `Create Plan` and `Host Plan` notebooks.

You are going to need to install PySyft on your Python environment to run them so follow the instructions here: https://github.com/OpenMined/PySyft/blob/dev/INSTALLATION.md

`SwiftSyft` currently supports version `0.2.5` of PySyft.

## Example App

The example app should work by default and is configured to use localhost to query hosted plans.

## License

SwiftSyft is available under the Apache 2 license. See the LICENSE file for more info.
