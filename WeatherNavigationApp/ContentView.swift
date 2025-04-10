import SwiftUI
import CoreLocation
import CoreLocationUI

struct Forecast: Codable, Identifiable {
    let id = UUID()
    let dt: Int
    let main: Main
    let weather: [Weather]
    
    struct Main: Codable {
        let temp: Double
    }
    
    struct Weather: Codable {
        let description: String
        let icon: String
    }
}

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var forecasts: [Forecast] = []
    @Published var locationStatus: CLAuthorizationStatus?
    
    private let locationManager = CLLocationManager()
    private let apiKey = "YOUR_API_KEY" // <- Replace this

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        locationManager.stopUpdatingLocation()
    }

    func fetchWeather(lat: Double, lon: Double) {
        let urlString = "https://pro.openweathermap.org/data/2.5/forecast/hourly?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=imperial"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
                DispatchQueue.main.async {
                    self.forecasts = decoded.list
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }.resume()
    }
    
    struct ForecastResponse: Codable {
        let list: [Forecast]
    }
}

struct ContentView: View {
    @StateObject var viewModel = WeatherViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.forecasts.prefix(12)) { forecast in
                VStack(alignment: .leading) {
                    Text("Temp: \(forecast.main.temp, specifier: "%.1f")°F")
                    Text(forecast.weather.first?.description.capitalized ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Next 12 Hours")
        }
    }
}

