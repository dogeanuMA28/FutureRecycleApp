import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from backend import Backend


def main():
    app = QGuiApplication(sys.argv)
    QCoreApplication.setOrganizationName("FutureRecycle")
    QCoreApplication.setApplicationName("ControlCenter")

    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    path = Path(__file__).resolve().parent / "main.qml"
    engine.load(QUrl.fromLocalFile(str(path)))
    if not engine.rootObjects():
        raise SystemExit("Could not load main.qml. See the QML error above.")
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
