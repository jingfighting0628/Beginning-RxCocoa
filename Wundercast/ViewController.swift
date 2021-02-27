/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
  @IBOutlet private var searchCityName: UITextField!
  @IBOutlet private var tempLabel: UILabel!
  @IBOutlet private var humidityLabel: UILabel!
  @IBOutlet private var iconLabel: UILabel!
  @IBOutlet private var cityNameLabel: UILabel!
  private let bag = DisposeBag()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    style()
    
    ApiController.shared.currentWeather(for: "London")
     .observeOn(MainScheduler.instance)
     .subscribe(onNext: { data in
    self.tempLabel.text = "\(data.temperature)° C"
    self.iconLabel.text = data.icon
    self.humidityLabel.text = "\(data.humidity)%"
    self.cityNameLabel.text = data.cityName
     })
        .disposed(by: bag)
    //这会将订阅的生命周期与DisposeBag的生命周期以及视图控制器的生命周期联系在一起。 这样既可以避免浪费资源，又可以避免在不处理订阅的情况下可能发生的意外事件或其他副作用。
    //您已经解决了第一个问题，因此您可以将注意力转向文本字段。 如前所述，RxCocoa在Cocoa的基础上增加了很多功能，因此您可以开始使用此功能来实现最终目标。 该框架使用协议扩展的功能，并将rx名称空间添加到许多UIKit组件中。
    //键入searchCityName.rx。 查看可用的属性和方法
    
    //您之前已经浏览过：文本。 此属性返回一个Observable，它是ControlProperty <String？>，它同时符合ObservableType和ObserverType，因此您可以订阅它，也可以向其添加新值，从而设置字段文本。
    //了解ControlProperty的基础知识之后，您可以改进代码以利用文本字段在虚拟数据中显示城市名称。 添加到viewDidLoad（）
/*
    let search =
    searchCityName.rx.text.orEmpty
        .filter{!$0.isEmpty}
 */
    let search = searchCityName.rx
        .controlEvent(.editingDidEndOnExit)
        .map{
            self.searchCityName.text ?? ""
        }
        
        /*
        .flatMap{
            
            text in
            ApiController.shared.currentWeather(for: text)
                .catchErrorJustReturn(.empty)
        }
 */
        
        .flatMapLatest{
            text in
            ApiController.shared.currentWeather(for: text)
                .catchErrorJustReturn(.empty)
        }
        .share(replay: 1)
        .observe(on: MainScheduler.instance)
    
    search.map(\.icon)
        .bind(to: iconLabel.rx.text)
        .disposed(by: bag)
    
    search.map{"\($0.humidity)%"}
        .bind(to: humidityLabel.rx.text)
        .disposed(by: bag)
    
    search.map(\.cityName)
        .bind(to: cityNameLabel.rx.text)
        .disposed(by: bag)
        
        
    
    //此代码与之前的代码有两个更改。
    //第一个是将flatMap更改为flatMapLatest，这将在新的网络请求启动时取消以前的任何网络请求。 如果没有它，您键入城市名称时可能会得到多个结果，因为没有任何事情可以取消先前待处理的请求。
    //第二个是将share（replay：1）添加到订阅，这使您的流可重用，并将一次性数据源转换为多用途Observable
    
    
    
    
    //注意：除了符合ObserverType的对象之外，您还可以在Relays上使用bind（to :)。 那些bind（to :)方法是单独的重载，因为中继不符合ObserverType。
    //最后，一个有趣的事实是，bind（to :)是subscribe（）的别名或语法糖。 调用bind（to：observer）将在内部调用subscription（observer）。 前者很简单，可以创建更有意义和直观的语法
    
    
    
    
    
    
    //此时，无论何时更改输入，标签都会更新为城市名称，但现在它始终会返回您的虚拟数据。 您知道该应用程序可以正确显示虚拟数据，因此现在该从API获取真实数据了
    //注意：catchErrorJustReturn运算符将在本书后面进行解释。 当您从API收到错误消息时，必须采取措施防止该可观察对象被处置。 例如，无效的城市名称返回404作为NSURLSession的错误。 在这种情况下，您想返回一个空的响应，以便在遇到错误时该应用不会停止运行
    
    //理解绑定的最简单方法是将关系视为两个实体之间的连接：
    //生产者，产生价值。
    //•消费者，处理生产者的价值。
    //消费者无法返回值。 在RxSwift中使用绑定时，这是一条通用规则
    //注意：如果以后要尝试双向绑定（例如，在数据模型属性和文本字段之间），可以使用以下四个实体来建模：两个生产者和两个消费者。 您可以想象，这会极大地增加代码的复杂性-不过，如果您愿意玩的话，那可能会很有趣
    //绑定的基本方法是bind（to :)，用于将可观察对象绑定到另一个实体。 使用者必须符合ObserverType，即只能接受新事件但不能订阅的只写实体ObserverType。
    //我们与RxSwift捆绑在一起的唯一类型是ObserverType，它是Subject，您之前已了解过Subject，因为它既符合ObserverType也符合ObservableType，因此您不仅可以向其中写入事件，还可以订阅它
    //后一种更改的强大功能将在MVVM专用章节的后面部分介绍，但目前，您只需意识到，可观察对象可以是Rx中大量可重用的实体，并且正确的建模可以使冗长且难以阅读的单一代码成为可能。 使用观察者来代替多用途且易于理解的观察者
    //What are ControlProperty and Driver?
    //•它们不会出错。
    //•在主调度程序上已观察到它们并已订阅它们。
    //•它们共享资源，这并不奇怪，因为它们都来自称为SharedSequence的实体。 驱动程序自动获取共享（重播：1），而信号获取共享（）。
    //这些实体确保某些内容始终显示在用户界面中，并且始终能够由用户界面处理。
    //RxCocoa特性包括：•ControlProperty和ControlEvent•驱动程序•Signal ControlProperty不是新的； 您刚刚使用过它，使用专用的rx名称空间将数据绑定到正确的用户界面组件。 顾名思义，它用于表示可以读取和修改的对象的属性
    //使用RxCocoa时，使用weak和Unowned的规则与使用常规Swift闭包时所遵循的规则相同，并且在调用Rx的闭包变体（如subscribe（onNext:）时主要是相关的。如果您的闭包是转义闭包，那么最好使用弱捕获组或无主捕获组；否则，您可能会得到一个保留周期，并且您的订阅将永远不会被释放。
   // 使用weak意味着您将获得对self的可选引用，而使用unowned将提供对self的隐式展开引用。你能想到自力更生吗？自食其力！，这意味着您在使用unowned时必须格外小心，因为它实际上是一种强制展开；如果对象不在那里，您的应用程序将崩溃。
    //由于这些原因雷文德里奇网站Swift指南https://bit.ly/3gA2m4N建议不要使用无主的
    
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    Appearance.applyBottomLine(to: searchCityName)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Style

  private func style() {
    view.backgroundColor = UIColor.aztec
    searchCityName.attributedPlaceholder = NSAttributedString(string: "City's Name",
                                                              attributes: [.foregroundColor: UIColor.textGrey])
    searchCityName.textColor = UIColor.ufoGreen
    tempLabel.textColor = UIColor.cream
    humidityLabel.textColor = UIColor.cream
    iconLabel.textColor = UIColor.cream
    cityNameLabel.textColor = UIColor.cream
  }
}
