import UIKit

precedencegroup ForwardApplication {
  associativity: left
}
precedencegroup SingleTypeComposition {
  associativity: right
  higherThan: ForwardApplication
}
infix operator <> : SingleTypeComposition
public func <> <A: AnyObject>(
  f: @escaping (A) -> Void,
  g: @escaping (A) -> Void
) -> (A) -> Void {
  return { a in
    f(a)
    g(a)
  }
}

func autoLayoutStyle(_ view: UIView)  {
  view.translatesAutoresizingMaskIntoConstraints = false
}
func baseButtonStyle(_ button: UIButton) {
  button.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
  button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
}

func borderStyle(color: UIColor, width: CGFloat) -> (UIView) -> Void {
  return {
    $0.layer.borderColor = color.cgColor
    $0.layer.borderWidth = width
  }
}

let roundedStyle: (UIView) -> Void = {
  $0.clipsToBounds = true
  $0.layer.cornerRadius = 6
}

let baseTextFieldStyle: (UITextField) -> Void = 
roundedStyle
<> borderStyle(color: UIColor(white: 0.75, alpha: 1), width: 1)
<> { (tf: UITextField) in
  tf.borderStyle = .roundedRect
  tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
}

let roundedButtonStyle = 
baseButtonStyle
<> roundedStyle

let filledButtonStyle = 
roundedButtonStyle
<> {
  $0.backgroundColor = .black
  $0.tintColor = .white
}

let borderButtonStyle =
roundedButtonStyle
<> borderStyle(color: .black, width: 2)

let rootStackViewStyle: (UIStackView) -> Void =
autoLayoutStyle
<> {
  $0.backgroundColor = .cyan
  $0.spacing = 10
  $0.distribution = .equalSpacing
  $0.alignment = .fill
  $0.axis = .vertical
}

extension UIButton {
  static var base: UIButton {
    let button = UIButton()
    button.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    return button
  }
  
  static var filled: UIButton {
    let button = self.rounded
    button.backgroundColor = .black
    button.tintColor = .white
    return button
  }
  
  static var rounded: UIButton {
    let button = self.base
    button.clipsToBounds = true
    button.layer.cornerRadius = 6
    return button
  }
}

class BaseButton: UIButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)
    self.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class RoundedButton: BaseButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.clipsToBounds = true
    self.layer.cornerRadius = 6
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class FilledButton: RoundedButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .black
    self.tintColor = .white
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


class MyViewController : UINavigationController {
  //  let filledButton = FilledButton()
  //  let roundedButton = RoundedButton()
  //  let filledButton = UIButton.filled
  //  let roundedButton = UIButton.rounded
  let roundedButton = UIButton()
  let filledButton = UIButton()
  let roundedTextField = UITextField()
  let borderButton = UIButton()
  let stackView = UIStackView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    rootStackViewStyle(stackView)
    self.view.addSubview(stackView)
    
    roundedButton.setTitle("roundedButton", for: .normal)
    roundedButtonStyle(roundedButton)
    self.stackView.addArrangedSubview(roundedButton)
    
    filledButton.setTitle("filledButton", for: .normal)
    filledButtonStyle(filledButton)
    self.stackView.addArrangedSubview(filledButton)
    
    baseTextFieldStyle(roundedTextField)
    self.stackView.addArrangedSubview(roundedTextField)
    
    borderButton.setTitle("borderButton", for: .normal)
    borderButtonStyle(borderButton)
    self.stackView.addArrangedSubview(borderButton)
    
    
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      //      stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 300),
      stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 300),
      stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
    ])
  }
}
// Present the view controller in the Live View window

import PlaygroundSupport
PlaygroundPage.current.liveView = MyViewController()

