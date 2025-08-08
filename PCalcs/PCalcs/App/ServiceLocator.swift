import Foundation

final class ServiceLocator: ObservableObject {
    let dataPackManager: DataPackManaging
    let calculatorAdapter: PerformanceCalculatorAdapting
    let weatherProvider: WeatherProvider

    init(
        dataPackManager: DataPackManaging = DataPackManager(),
        calculatorAdapter: PerformanceCalculatorAdapting = PerformanceCalculatorAdapter(),
        weatherProvider: WeatherProvider? = nil
    ) {
        self.dataPackManager = dataPackManager
        self.calculatorAdapter = calculatorAdapter
        if let wp = weatherProvider { self.weatherProvider = wp }
        else {
            #if DEMO_LOCK
            if let staging = Bundle.main.object(forInfoDictionaryKey: "WXProxyBaseURL_Staging") as? String, let url = URL(string: staging) {
                self.weatherProvider = RemoteWeatherProvider(baseURL: url)
            } else {
                self.weatherProvider = RemoteWeatherProvider(baseURL: URL(string: "https://proxy.example.com")!)
            }
            #else
            self.weatherProvider = RemoteWeatherProvider(baseURL: URL(string: "https://proxy.example.com")!)
            #endif
        }
    }
}