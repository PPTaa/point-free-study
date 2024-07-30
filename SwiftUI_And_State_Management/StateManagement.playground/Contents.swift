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
          destination: FavoritePrimesView(state: self.state)
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
  
}

struct CounterView: View {
  @ObservedObject var state: AppState
  @State var isPrimeModelShown: Bool = false
  @State var alertNthPrime: PrimeAlert?
  
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
        action: {
          nthPrime(
            self.state.count,
            callback: { prime in
              guard let prime = prime else { return }
              self.alertNthPrime = PrimeAlert(prime: prime)
            }
          )
        },
        label: {
          Text("What is the \(ordinal(self.state.count)) prime?")
        }
      )
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
        Button(action: { self.state.favoritePrimes.removeAll(where: { $0 == self.state.count }) }) {
          Text("Remove from favorite primes")
        }
      } else {
        Button(action: { self.state.favoritePrimes.append(self.state.count) }) {
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
  @ObservedObject var state: AppState
  
  var body: some View {
    List {
      ForEach(self.state.favoritePrimes, id: \.self) { prime in
        Text("\(prime)")
      }
      .onDelete { indexSet in
        for index in indexSet {
          self.state.favoritePrimes.remove(at: index)
        }
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
    state: AppState()
  )
)

