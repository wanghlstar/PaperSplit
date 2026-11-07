import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    private var window: NSWindow?
    private var webView: WKWebView?
    private var server: Process?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        startLocalServer()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let server = server, server.isRunning {
            server.terminate()
        }
    }

    // MARK: - Local server

    private func startLocalServer() {
        guard let resources = Bundle.main.resourceURL else {
            fail("应用资源缺失")
            return
        }

        let executable = resources.appendingPathComponent("papersplit-server")
        let www = resources.appendingPathComponent("www")
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            fail("缺少本地服务程序")
            return
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = ["--root", www.path, "--host", "127.0.0.1", "--port", "0"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            fail("无法启动本地服务：\(error.localizedDescription)")
            return
        }
        server = process

        let semaphore = DispatchSemaphore(value: 0)
        let handle = pipe.fileHandleForReading
        var buffer = Data()
        var port: Int?

        handle.readabilityHandler = { fileHandle in
            let chunk = fileHandle.availableData
            if chunk.isEmpty {
                semaphore.signal()
                return
            }
            buffer.append(chunk)
            guard let text = String(data: buffer, encoding: .utf8),
                  let range = text.range(of: "LISTENING ") else {
                return
            }
            let digits = text[range.upperBound...].prefix { $0.isNumber }
            if let value = Int(digits) {
                port = value
                semaphore.signal()
            }
        }

        let result = semaphore.wait(timeout: .now() + 10)
        handle.readabilityHandler = nil

        if result == .timedOut || port == nil {
            fail("本地服务启动超时")
            return
        }

        buildWindow(port: port!)
    }

    private func buildWindow(port: Int) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsMagnification = true

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PaperSplit"
        window.minSize = NSSize(width: 900, height: 620)
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.webView = webView

        if let url = URL(string: "http://127.0.0.1:\(port)/") {
            webView.load(URLRequest(url: url))
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func fail(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "PaperSplit"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "退出")
        alert.runModal()
        NSApp.terminate(nil)
    }

    // MARK: - Menu

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 PaperSplit", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出 PaperSplit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        let viewItem = NSMenuItem()
        let viewMenu = NSMenu(title: "显示")
        viewMenu.addItem(withTitle: "重新载入", action: #selector(reloadPage), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "放大", action: #selector(zoomIn), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "缩小", action: #selector(zoomOut), keyEquivalent: "-")
        viewMenu.addItem(withTitle: "实际大小", action: #selector(zoomReset), keyEquivalent: "0")
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func reloadPage() {
        webView?.reload()
    }

    @objc private func zoomIn() {
        webView?.magnification = min((webView?.magnification ?? 1) + 0.1, 3.0)
    }

    @objc private func zoomOut() {
        webView?.magnification = max((webView?.magnification ?? 1) - 0.1, 0.5)
    }

    @objc private func zoomReset() {
        webView?.magnification = 1.0
    }

    // MARK: - WKUIDelegate (JS dialogs)

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "PaperSplit"
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        if let window = window {
            alert.beginSheetModal(for: window) { _ in completionHandler() }
        } else {
            alert.runModal()
            completionHandler()
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "PaperSplit"
        alert.informativeText = message
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        if let window = window {
            alert.beginSheetModal(for: window) { response in
                completionHandler(response == .alertFirstButtonReturn)
            }
        } else {
            completionHandler(alert.runModal() == .alertFirstButtonReturn)
        }
    }

    // MARK: - WKDownloadDelegate (PDF export)

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

        if let window = window {
            panel.beginSheetModal(for: window) { result in
                completionHandler(result == .OK ? panel.url : nil)
            }
        } else {
            completionHandler(panel.runModal() == .OK ? panel.url : nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        NSSound.beep()
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let alert = NSAlert()
        alert.messageText = "保存失败"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
