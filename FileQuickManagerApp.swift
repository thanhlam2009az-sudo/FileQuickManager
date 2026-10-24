import SwiftUI

@main
struct FileQuickManagerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var folderURL: URL?
    @State private var status = "Chọn thư mục mà ứng dụng được phép truy cập."
    @State private var showPicker = false
    @State private var showDeleteConfirm = false
    @State private var showInstallConfirm = false

    private let fileNames = ["localConfig.json", "Assembly-CSharp-patch.bytes"]

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 54))
                    .padding(.top, 28)
                Text("File Quick Manager")
                    .font(.title2.bold())
                Text(folderURL?.lastPathComponent ?? "Chưa chọn thư mục")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button { showPicker = true } label: {
                    Label("Chọn thư mục đích", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { showInstallConfirm = true } label: {
                    Label("Chép 2 file vào thư mục", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(folderURL == nil)

                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("Xóa đúng 2 file", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(folderURL == nil)

                Text(status)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                Spacer()
                Text("Ứng dụng chỉ thao tác trong thư mục bạn chọn và được iOS cấp quyền.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(22)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPicker) {
                FolderPicker { url in
                    if let url {
                        folderURL = url
                        status = "Đã chọn: \(url.path)"
                    }
                }
            }
            .alert("Chép hai file?", isPresented: $showInstallConfirm) {
                Button("Hủy", role: .cancel) {}
                Button("Chép", role: .destructive) { installFiles() }
            } message: {
                Text("Nếu file cùng tên đã tồn tại, file đó sẽ được thay thế.")
            }
            .alert("Xóa hai file?", isPresented: $showDeleteConfirm) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) { deleteFiles() }
            } message: {
                Text("Chỉ xóa localConfig.json và Assembly-CSharp-patch.bytes trong thư mục đã chọn.")
            }
        }
    }

    private func installFiles() {
        guard let folderURL else { return }
        let granted = folderURL.startAccessingSecurityScopedResource()
        defer { if granted { folderURL.stopAccessingSecurityScopedResource() } }
        do {
            for name in fileNames {
                guard let source = Bundle.main.url(forResource: name, withExtension: nil) else {
                    throw NSError(domain: "FileQuickManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Thiếu file trong ứng dụng: \(name)"])
                }
                let destination = folderURL.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: source, to: destination)
            }
            status = "Đã chép xong 2 file."
        } catch { status = "Lỗi: \(error.localizedDescription)" }
    }

    private func deleteFiles() {
        guard let folderURL else { return }
        let granted = folderURL.startAccessingSecurityScopedResource()
        defer { if granted { folderURL.stopAccessingSecurityScopedResource() } }
        do {
            var removed = 0
            for name in fileNames {
                let target = folderURL.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                    removed += 1
                }
            }
            status = "Đã xóa \(removed) file."
        } catch { status = "Lỗi: \(error.localizedDescription)" }
    }


}

struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { onPick(nil); return }
            onPick(url)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { onPick(nil) }
    }
}
