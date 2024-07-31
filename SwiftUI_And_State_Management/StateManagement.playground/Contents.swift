import SwiftUI

struct ContentView: View {
  @ObservedObject var state: AppState
  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          destination: CounterView(state: self.state)
        ) {
          Text("Counter demo")
        }
        NavigationLink(
          destination: FavoritePrimesView(
            favoritePrimes: self.$state.favoritePrimes,
            activityFeed: self.$state.activityFeed
          )
        ) {
          Text("Favorite primes")
        }
      }
      .navigationTitle("State Management")
    }
  }
}

import Combine
class AppState: ObservableObject {
  @Published var count = 0
  @Published var favoritePrimes: [Int] = []
  @Published var loggedInUser: User?
  @Published var activityFeed: [Activity] = []
  
  struct User {
    let id: Int
    let name: String
    let bio: String
  }
  
  struct Activity {
    let timestamp: Date
    let type: ActivityType
    
    enum ActivityType {
      case addedFavoritePrime(Int)
      case removedFavoritePrime(Int)
    }
  }
  
}

struct CounterView: View {
  @ObservedObject var state: AppState
  @State var isPrimeModelShown: Bool = false
  @State var alertNthPrime: PrimeAlert?
  @State var isNthPrimeButtonDisable: Bool = false
  
  var body: some View {
    VStack {
      HStack {
        Button(
          action: {
            self.state.count -= 1
          },
          label: {
            Text("-")
          }
        )
        Text("\(self.state.count)")
        Button(
          action: {
            self.state.count += 1
          },
          label: {
            Text("+")
          }
        )
      }
      
      Button(
        action: {
          self.isPrimeModelShown = true
        },
        label: {
          Text("Is this prime?")
        }
      )
      Button(
        action: nthPrimeButtonAction,
        label: {
          Text("What is the \(ordinal(self.state.count)) prime?")
        }
      )
      .disabled(self.isNthPrimeButtonDisable)
    }
    .font(.title)
    .navigationTitle("Counter Demo")
    .sheet(isPresented: self.$isPrimeModelShown) {
      IsPrimeModelView(state: self.state)
    }
    .alert(item: self.$alertNthPrime) { n in
      Alert(
        title: Text("The \(ordinal(self.state.count)) prime is \(n.prime)"),
        dismissButton: Alert.Button.default(Text("OK"))
      )
    }
  }
  
  private func nthPrimeButtonAction() {
    self.isNthPrimeButtonDisable = true
    nthPrime(
      self.state.count,
      callback: { prime in
        guard let prime = prime else { return }
        self.alertNthPrime = PrimeAlert(prime: prime)
        self.isNthPrimeButtonDisable = false
      }
    )
  }
}

struct PrimeAlert: Identifiable {
  let prime: Int
  var id: Int { prime }
}


struct IsPrimeModelView: View {
  @ObservedObject var state: AppState
  var body: some View {
    if isPrime(self.state.count) {
      Text("\(self.state.count) is prime 🥳🥳 !!!")
      if self.state.favoritePrimes.contains(self.state.count) {
        Button(action: self.state.removeFavoritePrime) {
          Text("Remove from favorite primes")
        }
      } else {
        Button(action: self.state.addFavoritePrime) {
          Text("Save to favorite primes")
        }
      }
    } else {
      Text("\(self.state.count) is not prime :(")
    }
  }
}

private func isPrime(_ p: Int) -> Bool{
  if p <= 1 { return true }
  if p <= 3 { return true }
  for i in 2...Int(sqrt(Float(p))) {
    if p % i == 0 { return false }
  }
  return true
}

private func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}


struct WolframAlphaResult: Decodable {
  let queryresult: QueryResult
  
  struct QueryResult: Decodable {
    let pods: [Pod]
    
    struct Pod: Decodable {
      let primary: Bool?
      let subpods: [SubPod]
      
      struct SubPod: Decodable {
        let plaintext: String
      }
    }
  }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) {
  var component = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
  component.queryItems = [
    URLQueryItem(name: "input", value: query),
    URLQueryItem(name: "format", value: "plaintext"),
    URLQueryItem(name: "output", value: "JSON"),
    URLQueryItem(name: "appid", value: "3JVL8V-7TU2WK5U8Q"),
  ]
  
  URLSession.shared.dataTask(
    with: component.url(relativeTo: nil)!
  ) { data, response, error in
    callback(
      data.flatMap {
        try? JSONDecoder().decode(WolframAlphaResult.self, from: $0)
      }
    )
  }
  .resume()
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) {
  wolframAlpha(query: "prime \(n)") { result in
    callback(
      result
        .flatMap {
          $0.queryresult
            .pods
            .first(where: { $0.primary == .some(true) })?
            .subpods
            .first?
            .plaintext
        }
        .flatMap(Int.init)
    )
  }
}


struct FavoritePrimesView: View {
  @Binding var favoritePrimes: [Int]
  @Binding var activityFeed: [AppState.Activity]
  
  var body: some View {
    List {
      ForEach(self.favoritePrimes, id: \.self) { prime in
        Text("\(prime)")
      }
      .onDelete { indexSet in
        for index in indexSet {
          let prime = self.favoritePrimes[index]
          self.favoritePrimes.remove(at: index)
          self.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
        }
      }
    }
      .navigationTitle("Favorite Primes")
  }
}
//nthPrime(1_000_000) { p in
//  print(p)
//}

extension AppState {
  func addFavoritePrime() {
    self.favoritePrimes.append(self.count)
    self.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(self.count)))
  }
  
  func removeFavoritePrime(_ prime: Int) {
    self.favoritePrimes.removeAll(where: { $0 == prime })
    self.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
  }
  
  func removeFavoritePrime() {
    self.removeFavoritePrime(self.count)
  }
  
  func removeFavoritePrime(at indexSet: IndexSet) {
    for index in indexSet {
      self.removeFavoritePrime(self.favoritePrimes[index])
    }
  }
}

import PlaygroundSupport

PlaygroundPage.current.liveView = UIHostingController(
  rootView: ContentView(
    state: AppState()
  )
)

