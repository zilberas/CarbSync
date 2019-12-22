![Screenshot](carbSync.jpg)

# Digital Carburetor Synchronizer

A tool for carb synchronisation.
Uses HX710B chips to read vacuum sensors, and libFTDI to transfer data via USB cable from FT232H (bitbang mode) device.

## Contents

A repo consists of:
* driver for HX710B chip written in C
* macOS app with UI for 4 sensors
* sensor readings taken from Honda GL1000 - app can run in Simulator mode


## Usage

Driver requires libFTDI to be installed

```bash
brew install libftdi
```

## Contributing
Pull requests are welcome.

## License
[Apache License, version 2.0.](http://www.apache.org/licenses/LICENSE-2.0)
