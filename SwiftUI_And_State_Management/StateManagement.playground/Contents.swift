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
          destination: EmptyView()
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
  
}

struct CounterView: View {
  @ObservedObject var state: AppState
  
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
        action: {},
        label: {
          Text("Is this prime?")
        }
      )
      Button(
        action: {},
        label: {
          Text("What is the \(ordinal(self.state.count)) prime?")
        }
      )
    }
    .font(.title)
    .navigationTitle("Counter Demo")
  }
}

private func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}


import PlaygroundSupport

PlaygroundPage.current.liveView = UIHostingController(
  rootView: ContentView(
    state: AppState()
  )
)
