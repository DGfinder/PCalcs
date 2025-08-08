import Foundation

final class ServiceLocator: ObservableObject {
    let dataPackManager: DataPackManaging
    let calculatorAdapter: PerformanceCalculatorAdapting
    let weatherProvider: WeatherProvider

    init(
        dataPackManager: DataPackManaging = DataPackManager(),
        calculatorAdapter: PerformanceCalculatorAdapting = PerformanceCalculatorAdapter(),
        weatherProvider: WeatherProvider = RemoteWeatherProvider(baseURL: URL(string: "https://proxy.example.com")!)
    ) {
        self.dataPackManager = dataPackManager
        self.calculatorAdapter = calculatorAdapter
        self.weatherProvider = weatherProvider
    }
}