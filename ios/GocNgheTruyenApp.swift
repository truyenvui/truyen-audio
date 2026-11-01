import SwiftUI
import WebKit

@main
struct GocNgheTruyenApp: App {
    var body: some Scene {
        WindowGroup { BrowserScreen() }
    }
}

@MainActor
final class BrowserModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var address = "https://"
    @Published var pageTitle = "Trình duyệt truyện"
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var extractedText = ""
    @Published var extractedTitle = ""

    let webView: WKWebView

    override init() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }

    func openAddress() {
        let raw = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        let candidate = raw.contains("://") ? raw : "https://" + raw
        guard let url = URL(string: candidate),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return }
        address = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    func goBack() { if webView.canGoBack { webView.goBack() } }
    func goForward() { if webView.canGoForward { webView.goForward() } }
    func reload() { webView.reload() }

    // Chỉ đọc văn bản đang hiển thị trong trang người dùng đã mở.
    // Không vượt CAPTCHA, đăng nhập, paywall hoặc cơ chế chống truy cập tự động.
    func extractCurrentPage() {
        let script = """
        (() => {
          const candidates = Array.from(document.querySelectorAll(
            'article, main, [role="main"], .chapter-content, .content, .entry-content'
          ));
          const usable = candidates
            .map(el => ({ text: (el.innerText || '').trim(), score: (el.innerText || '').trim().length }))
            .filter(x => x.score > 200)
            .sort((a, b) => b.score - a.score);
          const text = usable.length ? usable[0].text : (document.body?.innerText || '');
          return { title: document.title || '', text };
        })();
        """
        webView.evaluateJavaScript(script) { [weak self] result, error in
            guard let self else { return }
            guard error == nil,
                  let data = result as? [String: Any],
                  let text = data["text"] as? String else { return }
            DispatchQueue.main.async {
                self.extractedTitle = (data["title"] as? String) ?? self.pageTitle
                self.extractedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        syncNavigation(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        pageTitle = webView.title ?? "Trang truyện"
        address = webView.url?.absoluteString ?? address
        syncNavigation(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        syncNavigation(webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        syncNavigation(webView)
    }

    private func syncNavigation(_ webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct BrowserScreen: View {
    @StateObject private var model = BrowserModel()
    @State private var showExtracted = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    TextField("Dán link trang truyện…", text: $model.address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit { model.openAddress() }
                        .padding(11)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Mở") { model.openAddress() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                HStack {
                    Button { model.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!model.canGoBack)
                    Button { model.goForward() } label: { Image(systemName: "chevron.right") }
                        .disabled(!model.canGoForward)
                    Button { model.reload() } label: { Image(systemName: "arrow.clockwise") }
                    Spacer()
                    if model.isLoading { ProgressView() }
                    Button {
                        model.extractCurrentPage()
                        showExtracted = true
                    } label: {
                        Label("Trích xuất", systemImage: "doc.text.viewfinder")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                WebViewContainer(webView: model.webView)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 8)
            }
            .navigationTitle("Góc Nghe Truyện")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExtracted) {
                NavigationStack {
                    Group {
                        if model.extractedText.isEmpty {
                            ContentUnavailableView(
                                "Chưa trích xuất được",
                                systemImage: "doc.text",
                                description: Text("Hãy mở một trang có nội dung đọc được rồi thử lại.")
                            )
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(model.extractedTitle).font(.title2.bold())
                                    Text(model.extractedText)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                            }
                        }
                    }
                    .navigationTitle("Nội dung chương")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Đóng") { showExtracted = false }
                        }
                    }
                }
            }
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
