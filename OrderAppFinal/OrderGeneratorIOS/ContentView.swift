import SwiftUI
import WebKit
import Photos

struct ContentView: View {
    var body: some View {
        OrderWebView()
            .ignoresSafeArea()
    }
}

struct OrderWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: "savePNG")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = webView
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "savePNG")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "savePNG",
                  let body = message.body as? [String: Any],
                  let dataURL = body["dataUrl"] as? String else {
                notifyJavaScript(success: false, message: "收唔到 PNG 資料。")
                return
            }
            let fileName = (body["fileName"] as? String) ?? "訂單畫面.png"
            savePNGToPhotos(dataURL: dataURL, fileName: fileName)
        }

        private func savePNGToPhotos(dataURL: String, fileName: String) {
            guard let commaIndex = dataURL.firstIndex(of: ",") else {
                notifyJavaScript(success: false, message: "PNG 格式錯誤。")
                return
            }
            let base64 = String(dataURL[dataURL.index(after: commaIndex)...])
            guard let data = Data(base64Encoded: base64) else {
                notifyJavaScript(success: false, message: "PNG 解碼失敗。")
                return
            }

            requestPhotoPermission { [weak self] allowed in
                guard allowed else {
                    self?.notifyJavaScript(success: false, message: "未有相簿權限。請到 iPhone「設定」→ 本 App →「相片」，允許加入相片。")
                    return
                }

                let options = PHAssetResourceCreationOptions()
                options.originalFilename = fileName
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: options)
                }) { [weak self] success, error in
                    self?.notifyJavaScript(
                        success: success,
                        message: success ? "PNG 已儲存到相簿。" : "儲存失敗：\(error?.localizedDescription ?? "未知錯誤")"
                    )
                }
            }
        }

        private func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            default:
                completion(false)
            }
        }

        private func notifyJavaScript(success: Bool, message: String) {
            let escaped = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            let js = "nativeSaveCompleted(\(success ? "true" : "false"), \"\(escaped)\")"
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}
