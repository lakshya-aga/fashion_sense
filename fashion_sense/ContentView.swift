import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraClicker: Bool = false
    @State private var cameraClickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var showAPIResponseView: Bool = false // New state variable

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack {
                            if let imagePath = item.imagePath,
                               let uiImage = UIImage(contentsOfFile: imagePath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 300, maxHeight: 300)
                            }
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        }
                    } label: {
                        if let imagePath = item.imagePath,
                           let uiImage = UIImage(contentsOfFile: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 300, maxHeight: 300)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Button(action: {
                            imagePickerSourceType = .photoLibrary
                            showImagePicker = true
                        }) {
                            Label("Upload from Gallery", systemImage: "photo.on.rectangle")
                        }
                        Button(action: {
                            imagePickerSourceType = .camera // show camera logic
                            showImagePicker = true
                        }) {
                            Label("Take a Photo", systemImage: "camera")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        makeAPICall()
                        showAPIResponseView = true // Show APIResponseView
                    }) {
                        Label("Upload Images", systemImage: "icloud.and.arrow.up")
                    }
                }
                ToolbarItem {
                                    Button(action: clickPictureAndCompareWithExisting) {
                                        Label("Get opinions", systemImage: "camera")
                                    }
                                }
            }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType, selectedImage: $selectedImage, onImagePicked: { image in
                if let image = image {
                    saveImageAndAddItem(image)
                }
            })
        }
        .sheet(isPresented: $showAPIResponseView) {
            APIResponseView() // Present the new view
        }
    }
    private func clickPictureAndCompareWithExisting() {
        cameraClickerSourceType = .camera
        showCameraClicker = true
        
    }
    
    private func saveImageAndAddItem(_ image: UIImage) {
        if let imagePath = saveImage(image) {
            withAnimation {
                let newItem = Item(timestamp: Date(), imagePath: imagePath)
                modelContext.insert(newItem)
            }
        }
    }

    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return nil }

        let filename = getDocumentsDirectory().appendingPathComponent(UUID().uuidString + ".png")
        do {
            try data.write(to: filename)
            return filename.path
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func makeAPICall() {
        var images = items.compactMap { item -> UIImage? in
            guard let imagePath = item.imagePath else { return nil }
            return UIImage(contentsOfFile: imagePath)
        }

        if let latestImage = selectedImage {
            images.append(latestImage)
        }

        uploadImages(images: images)
    }

    private func uploadImages(images: [UIImage]) {
        // Prepare your URL and request
        guard let url = URL(string: "https://your-api-endpoint.com/upload") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create a boundary for multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create the body
        let body = NSMutableData()

        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else { continue }

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images[]\"; filename=\"\(UUID().uuidString).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body as Data

        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to upload images: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Images uploaded successfully")
            } else {
                print("Failed to upload images")
            }
        }.resume()
    }
}
