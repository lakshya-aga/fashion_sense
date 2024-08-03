import SwiftUI

struct APIResponseView: View {
    @State private var apiData: [String] = []
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    List(apiData, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            .navigationTitle("API Response")
            .onAppear(perform: fetchAPIData)
        }
    }

    private func fetchAPIData() {
        guard let url = URL(string: "https://www.google.com") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to fetch data: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                // Assuming the response is a JSON array of strings
                let decodedData = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    self.apiData = decodedData
                    self.isLoading = false
                }
            } catch {
                print("Failed to decode data: \(error)")
            }
        }.resume()
    }
}
