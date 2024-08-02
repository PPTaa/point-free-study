import SwiftUI

struct ContentView: View {
  @ObservedObject var store: Store<AppState, AppAction>
  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          destination: CounterView(store: self.store)
        ) {
          Text("Counter demo")
        }
        NavigationLink(
          destination: FavoritePrimesView(store: self.store)
        ) {
          Text("Favorite primes")
        }
      }
      .navigationTitle("State Management")
    }
  }
}

import Combine
struct AppState {
  var count = 0
  var favoritePrimes: [Int] = []
  var loggedInUser: User?
  var activityFeed: [Activity] = []
  
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
enum CounterAction {
  case incrTapped
  case decrTapped
}

enum PrimeModalAction {
  case saveFavoritePrimeTapped
  case removeFavoritePrimeTapped
}

enum FavoritePrimesAction {
  case deleteFavoritePrimes(IndexSet)
}

enum AppAction {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
  case favoritePrimes(FavoritePrimesAction)
}

func appReducer(state: inout AppState, action : AppAction) {
  switch action {
  case .counter(.incrTapped):
    state.count += 1
    
  case .counter(.decrTapped):
    state.count -= 1
  
  case .primeModal(.saveFavoritePrimeTapped):
    state.favoritePrimes.append(state.count)
    state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
  
  case .primeModal(.removeFavoritePrimeTapped):
    state.favoritePrimes.removeAll(where: { $0 == state.count })
    state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
  case .favoritePrimes(.deleteFavoritePrimes(let indexSet)):
    for index in indexSet {
      let prime = state.favoritePrimes[index]
      state.favoritePrimes.remove(at: index)
      state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
    }
    
  }
}

var state = AppState()
print(appReducer(state: &state, action: .counter(.incrTapped)))
print(appReducer(state: &state, action: .counter(.decrTapped)))


final class Store<Value, Action>: ObservableObject {
  let reducer: (inout Value, Action) -> Void
  @Published var value: Value
  
  init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
    self.reducer = reducer
    self.value = initialValue
  }
  
  func send(_ action: Action) {
    self.reducer(&self.value, action)
  }
}

struct CounterView: View {
  @ObservedObject var store: Store<AppState, AppAction>
  @State var isPrimeModelShown: Bool = false
  @State var alertNthPrime: PrimeAlert?
  @State var isNthPrimeButtonDisable: Bool = false
  
  var body: some View {
    VStack {
      HStack {
        Button(
          action: { self.store.send(.counter(.decrTapped)) },
          label: {
            Text("-")
          }
        )
        Text("\(self.store.value.count)")
        Button(
          action: { self.store.send(.counter(.incrTapped)) },
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
          Text("What is the \(ordinal(self.store.value.count)) prime?")
        }
      )
      .disabled(self.isNthPrimeButtonDisable)
    }
    .font(.title)
    .navigationTitle("Counter Demo")
    .sheet(isPresented: self.$isPrimeModelShown) {
      IsPrimeModelView(store: self.store)
    }
    .alert(item: self.$alertNthPrime) { n in
      Alert(
        title: Text("The \(ordinal(self.store.value.count)) prime is \(n.prime)"),
        dismissButton: Alert.Button.default(Text("OK"))
      )
    }
  }
  
  private func nthPrimeButtonAction() {
    self.isNthPrimeButtonDisable = true
    nthPrime(
      self.store.value.count,
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
  @ObservedObject var store: Store<AppState, AppAction>
  var body: some View {
    if isPrime(self.store.value.count) {
      Text("\(self.store.value.count) is prime 🥳🥳 !!!")
      if self.store.value.favoritePrimes.contains(self.store.value.count) {
        Button(action: { self.store.send(.primeModal(.removeFavoritePrimeTapped))
        }) {
          Text("Remove from favorite primes")
        }
      } else {
        Button(action: {
          self.store.send(.primeModal(.saveFavoritePrimeTapped))
        }) {
          Text("Save to favorite primes")
        }
      }
    } else {
      Text("\(self.store.value.count) is not prime :(")
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
  @ObservedObject var store: Store<AppState, AppAction>
  
  var body: some View {
    List {
      ForEach(self.store.value.favoritePrimes, id: \.self) { prime in
        Text("\(prime)")
      }
      .onDelete { indexSet in
        self.store.send(.favoritePrimes(.deleteFavoritePrimes(indexSet)))
      }
    }
      .navigationTitle("Favorite Primes")
  }
}
//nthPrime(1_000_000) { p in
//  print(p)
//}

import PlaygroundSupport

PlaygroundPage.current.liveView = UIHostingController(
  rootView: ContentView(
    store: Store(
      initialValue: AppState(),
      reducer: appReducer
    )
  )
)


