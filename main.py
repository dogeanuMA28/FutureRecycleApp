"""Launch the FutureRecycle desktop demo on Linux, Windows or macOS."""
import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QEvent, QStandardPaths, Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from auth import Session
from backend import Backend


QML_DIR = Path(__file__).resolve().parent


def load_window(engine, filename):
    engine.load(QUrl.fromLocalFile(str(QML_DIR / filename)))
    if not engine.rootObjects():
        raise RuntimeError(f"Could not load {filename}. See the QML error above.")
    return engine.rootObjects()[0]


def main():
    app = QGuiApplication(sys.argv)
    QCoreApplication.setOrganizationName("FutureRecycle")
    QCoreApplication.setApplicationName("ControlCenter")

    storage = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
    data_dir = Path(storage) if storage else Path.home() / ".local/share/FutureRecycle"
    session = Session(data_dir / "accounts.sqlite3", app)
    login_engine = QQmlApplicationEngine(app)
    login_engine.rootContext().setContextProperty("session", session)
    login_window = load_window(login_engine, "Login.qml")
    dashboard_engine = None

    def update_window():
        nonlocal dashboard_engine
        if session.username and dashboard_engine is None:
            dashboard_engine = QQmlApplicationEngine(app)
            backend = Backend(parent=dashboard_engine, data_file=data_dir / "state.json")
            dashboard_engine.rootContext().setContextProperty("backend", backend)
            dashboard_engine.rootContext().setContextProperty("session", session)
            try:
                load_window(dashboard_engine, "main.qml")
            except RuntimeError as error:
                print(error, file=sys.stderr)
                app.exit(1)
                return
            login_window.hide()
        elif not session.username and dashboard_engine is not None:
            login_window.show()
            login_window.requestActivate()
            dashboard_engine.rootObjects()[0].hide()
            dashboard_engine.deleteLater()
            dashboard_engine = None

    session.changed.connect(update_window, Qt.ConnectionType.QueuedConnection)
    try:
        return app.exec()
    finally:
        if dashboard_engine is not None:
            dashboard_engine.deleteLater()
        login_engine.deleteLater()
        QCoreApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)
        session.close()


if __name__ == "__main__":
    sys.exit(main())
