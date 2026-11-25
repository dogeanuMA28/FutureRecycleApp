# ♻️ FutureRecycle — Smart Recycling Operations Dashboard

**FutureRecycle** is a cross-platform desktop application built with **Python, PySide6, and Qt Quick/QML**.

It is a customer-facing management dashboard for a fictional company that provides intelligent recycling stations to municipalities, universities, residential complexes, and other organizations.

The application allows customers to monitor their recycling stations, manage collections, report maintenance problems, analyze recycling activity, and evaluate station performance.

> **Academic project:** FutureRecycle is an educational simulation. It does not connect to real recycling stations, waste collection teams, or an actual AI image-recognition model.

---

## Features

| Feature | Description |
|---|---|
| **Overview Dashboard** | Monitor the entire recycling network, key statistics, and recent activity. |
| **Smart Stations** | Add and manage multiple recycling stations, each with independent containers. |
| **Station Health Score** | Evaluate station health on a 0–100 scale using status, container capacity, and maintenance issues. |
| **Station Map** | View fictional recycling stations on a real map of Romania using OpenStreetMap. |
| **Collection Management** | Request, schedule, cancel, and complete waste collection operations. |
| **Pickup Calendar** | Plan collections using dates and time windows. |
| **Alerts** | Identify full containers, offline stations, and critical maintenance problems. |
| **Maintenance** | Create and track equipment support tickets. |
| **Fill Forecasts** | Estimate when containers will reach capacity using configurable simulation rates. |
| **Analytics** | Analyze recycling statistics by material and station. |
| **Reports** | Generate operational summaries and export CSV files. |
| **Activity History** | Track simulated station activity, collections, and maintenance events. |
| **AI Detection Demo** | Simulate waste classification from uploaded image filenames. |
| **Settings** | Configure the simulation and choose presentation scenarios. |

All application data is stored locally using JSON.

---

## Technology Stack

- **Python 3.10+** — application logic and backend
- **PySide6** — Qt bindings for Python
- **Qt Quick / QML** — desktop user interface
- **Qt Location** — geographic map integration
- **OpenStreetMap** — real geographic map tiles
- **JSON** — local data persistence
- **CSV** — report exports

The application does not require a web server or database server.

## System Requirements

- Windows 10/11, Ubuntu 22.04+, or CachyOS
- Python 3.10 or newer
- Python `pip` and `venv`
- Internet connection for loading the Romania map

The rest of the simulation works offline.

The project's `requirements.txt` contains:

```text
PySide6>=6.6,<7
```

Install the complete PySide6 package so Qt Location and Qt Positioning are available.

---

# Installation

## 1. CachyOS (Fish Shell)

Open a terminal and make sure Python is installed:

```fish
sudo pacman -S --needed python python-pip
```

Navigate to the FutureRecycle project folder.

For example:

```fish
cd ~/facultate/management_de_proiect/gepeto/FutureRecycle
```

Create a Python virtual environment:

```fish
python -m venv .venv
```

Activate it using Fish:

```fish
source .venv/bin/activate.fish
```

Install the application dependencies:

```fish
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Start FutureRecycle:

```fish
python main.py
```

### Launching FutureRecycle again

For subsequent launches:

```fish
cd /path/to/FutureRecycle
source .venv/bin/activate.fish
python main.py
```

Alternatively, use the included Fish launcher:

```fish
fish run.fish
```

## 2. Ubuntu (Bash)

Open a terminal and install the required Python tools:

```bash
sudo apt update
sudo apt install python3 python3-venv python3-pip
```

Navigate to the FutureRecycle project folder:

```bash
cd /path/to/FutureRecycle
```

Create a virtual environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Run the application:

```bash
python main.py
```

### Launching FutureRecycle again

```bash
cd /path/to/FutureRecycle
source .venv/bin/activate
python main.py
```

If Qt reports missing XCB or OpenGL libraries, you can try installing:

```bash
sudo apt install libxcb-cursor0 libxkbcommon-x11-0 libopengl0
```

Only install these additional libraries if the error indicates they are needed.

## 3. Windows 10 / 11 (PowerShell)

### Install Python

Download a 64-bit version of Python from:

https://www.python.org/downloads/windows/

Install Python and make sure the Python launcher (`py`) is available.

Verify the installation by opening PowerShell:

```powershell
py --version
```

### Set up FutureRecycle

Extract the project and open PowerShell inside the folder containing `main.py`.

Create a virtual environment:

```powershell
py -3 -m venv .venv
```

Install dependencies using the virtual environment's Python:

```powershell
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Run FutureRecycle:

```powershell
.\.venv\Scripts\python.exe main.py
```

### Launching FutureRecycle again

```powershell
cd C:\path\to\FutureRecycle
.\.venv\Scripts\python.exe main.py
```

These instructions do not require activating the virtual environment or changing PowerShell's execution policy.

If `py` is unavailable, try `python -m venv .venv` after confirming Python is installed.

---

# How to Use the Application

## Monitoring Stations

Open **Smart Stations** to view all registered recycling stations.

Each station contains three virtual recycling compartments:

- Plastic
- Paper
- Metal

Each station maintains its own statistics, fill levels, and operational status.

The Station Health Score provides a simulated operational rating based on station availability, container capacity, and unresolved maintenance tickets.

## Romania Station Map

Open **Station Map** to view stations on the interactive map.

The map supports selecting stations, zooming, dragging, and manually updating the positions of fictional stations.

It displays a real geographic background provided by OpenStreetMap. However, the station locations are demonstration data, not live GPS measurements.

An internet connection is required to load the map tiles.

## Collection Management

Customers can request waste collection for individual station containers.

The typical workflow is:

1. Select a station and material.
2. Submit a collection request.
3. Schedule the collection using Pickup Calendar.
4. Mark the collection as completed.

Once a collection is completed, the corresponding virtual container is emptied automatically.

Only one active collection request per station and material is allowed.

The application does not contact real collection teams.

## Alerts and Maintenance

FutureRecycle generates simulated alerts for conditions such as high container fill levels, offline stations, and urgent maintenance problems.

Maintenance tickets can be created and progressed through their lifecycle.

When a relevant operational problem is resolved, the associated alert or station health score updates accordingly.

## AI Detection Demo

The scanner allows users to upload an image and simulate waste classification.

**Important:** classification is based on keywords in the image's filename, not analysis of the image pixels.

Example filenames:

| Filename | Simulated Result |
|---|---|
| `plastic_bottle.jpg` | Plastic |
| `paper_sheet.png` | Paper |
| `metal_can.jpg` | Metal |
| `unknown.jpg` | Unknown / Manual Review |

A successful simulated scan updates the selected station's recycling statistics and container fill level.

## Analytics and Reports

The Analytics page displays recycling performance and material distribution.

The Reports page allows users to review operational summaries and export CSV files.

Because the demo measures simulated object counts rather than real waste weight, any environmental estimates must be clearly distinguished from measured quantities.

---

# Presentation Scenarios

FutureRecycle includes several simulation presets under **Settings → Presentation Scenarios**.

**Normal Operation** simulates a healthy recycling network.

**Busy Day** increases container fill levels to demonstrate capacity warnings and collection requests.

**Critical Incident** simulates serious operational problems, such as an offline station and urgent maintenance.

**Service Recovery** simulates resolving outstanding issues and restoring network operation.

These scenarios are designed for university presentations and demonstrations.

Changing a scenario can modify saved simulation records.

---

# Data Storage

FutureRecycle automatically saves its data to a local JSON file.

The application prints the exact storage location in the terminal when it starts.

Typical Linux location:

```text
~/.local/share/FutureRecycle/ControlCenter/state.json
```

On Windows, the file is stored under the user's application-data directory, typically within `%APPDATA%`.

The exact location can vary by operating system.

**Important:** Back up your state file before resetting the simulation, restoring demo data, or switching project versions.

The `.venv` directory should not be copied between different operating systems.

---

# Troubleshooting

## PySide6 is not installed

If you encounter:

```text
ModuleNotFoundError: No module named 'PySide6'
```

Make sure the virtual environment is active and install the dependencies again:

```bash
python -m pip install -r requirements.txt
```

## Qt Location is missing

If the Romania map reports a missing `QtLocation` module, install the full PySide6 package:

```bash
python -m pip install --upgrade "PySide6>=6.6,<7" PySide6-Addons
```

On Windows, use the virtual environment's Python executable instead of `python`.

You can check the Python bindings with:

```bash
python -c "from PySide6 import QtLocation, QtPositioning; print('Qt Location available')"
```

This check confirms the Python modules are installed but does not guarantee that every QML plugin loads correctly.

## The Romania map shows an API-key watermark

Ensure that you are using the updated `RomaniaMap.qml` configured to select public OpenStreetMap tiles.

The academic demo should not require purchasing an API key.

## The map is blank or cannot be moved

Check your internet connection and verify that the updated map file includes Qt 6 `DragHandler` and `WheelHandler` controls.

Older configurations using the obsolete `gesture` property may not work correctly.

## The application cannot load `main.qml`

Make sure all required files are in the same project directory, including the individual page files, shared QML components, and `assets` directory.

If the Station Health Score has been integrated, ensure `Health.js` and `StationHealth.qml` are also present.

Run the application from a terminal to read the exact QML error.

## Collection requests fail

A collection request can be rejected when the selected container is empty or another active collection already exists for the same material and station.

A collection must be scheduled before being marked completed.

---

# Running Tests

FutureRecycle includes Python backend tests.

With the virtual environment active, run:

```bash
python -m unittest discover -s tests -v
```

You can also verify Python syntax:

```bash
python -m py_compile main.py backend.py
```

On Windows, use `.\.venv\Scripts\python.exe` instead of `python` when running without virtual environment activation.

---

# Project Structure

```text
FutureRecycle/
├── main.py
├── main.qml
├── backend.py
├── RomaniaMap.qml
├── Health.js
├── StationHealth.qml
├── OverviewPage.qml
├── StationsPage.qml
├── MapPage.qml
├── CollectionsPage.qml
├── CalendarPage.qml
├── AlertsPage.qml
├── MaintenancePage.qml
├── AnalyticsPage.qml
├── ForecastsPage.qml
├── ReportsPage.qml
├── ActivityPage.qml
├── ScannerPage.qml
├── SettingsPage.qml
├── assets/
├── tests/
├── requirements.txt
├── run.fish
└── README.md
```

The health-score files are part of the later extension and must be present if that feature has been integrated.

---

# Limitations

FutureRecycle is an educational desktop simulation.

The current application does not include real recycling hardware integration, real-time sensor measurements, live GPS tracking, cloud accounts, online payments, operational pickup dispatch, or a trained computer-vision model.

Collection requests, maintenance tickets, alerts, station health scores, and fill-level predictions are simulated.

The geographic map uses real map tiles, but the recycling stations shown on it are fictional.

Map data and tiles: © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).

Use of public map tiles is subject to the [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/).

---

**FutureRecycle — University Project / Educational Simulation**