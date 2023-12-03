//
//  BriefPagingControl
//
//  Created by Youngkyu Seo on 12/3/23.
//

import SwiftUI

public struct BriefPagingControl: View {
    
    private let numberOfPages: Int
    @Binding private var currentPage: Int
    
    private let indicatorSize: CGFloat
    private let spacing: CGFloat
    private let currentIndicatorColor: Color
    private let indicatorColor: Color
    private let numberOfMainIndicators: IndicatorType
    private let hidesForSinglePage: Bool
    private let animation: Animation
    
    @State private var activePage: Int
    @State private var displayedPosition: Int
    @State private var adjustedOffset: CGFloat
    
    
    public init(numberOfPages: Int, currentPage: Binding<Int>, setup: ((inout PagingControlConfig) -> Void)? = nil) {
        
        self.numberOfPages = numberOfPages
        self._currentPage = currentPage
        
        var config = PagingControlConfig()
        setup?(&config)
        
        self.indicatorSize = config.indicatorSize
        self.spacing = config.spacing
        self.currentIndicatorColor = config.currentIndicatorColor
        self.indicatorColor = config.indicatorColor
        self.numberOfMainIndicators = config.numberOfMainIndicators
        self.hidesForSinglePage = config.hidesForSinglePage
        self.animation = config.animation
        
        let activePage = currentPage.wrappedValue
        let displayedPosition = numberOfMainIndicators.initialPosition(of: activePage, numberOfPages: numberOfPages)
        let basicOffset = CGFloat(numberOfPages - numberOfMainIndicators.rawValue) * (indicatorSize + spacing) / 2
        let adjustedOffset = basicOffset - CGFloat(activePage - displayedPosition - numberOfMainIndicators.halfValue) * (indicatorSize + spacing)
        
        self.activePage = activePage
        self.displayedPosition = displayedPosition
        self.adjustedOffset = adjustedOffset
    }
    
    public var body: some View {
        
        VStack {
            if numberOfPages > numberOfMainIndicators.rawValue {
                
                HStack(spacing: spacing) {
                    ForEach(0..<numberOfPages, id: \.self) { page in
                        let size = calculateSize(page)
                        
                        Circle()
                            .fill(activePage == page ? currentIndicatorColor : indicatorColor)
                            .frame(width: size, height: size)
                            .frame(width: indicatorSize, height: indicatorSize, alignment: .center)
                    }
                }
                .offset(x: adjustedOffset)
                .frame(width: (indicatorSize + spacing) * CGFloat(numberOfMainIndicators.rawValue + 4 + 1))
                .onChange(of: currentPage) { [previousPage = currentPage] nextPage in
                    withAnimation(animation) {
                        if previousPage < nextPage {
                            if displayedPosition + 1 > numberOfMainIndicators.halfValue {
                                activePage += 1
                                adjustedOffset -= (indicatorSize + spacing)
                            } else {
                                activePage += 1
                                displayedPosition += 1
                            }
                        } else {
                            if displayedPosition - 1 < -numberOfMainIndicators.halfValue {
                                activePage -= 1
                                adjustedOffset += (indicatorSize + spacing)
                            } else {
                                activePage -= 1
                                displayedPosition -= 1
                            }
                        }
                    }
                }
            } else {
                
                HStack(spacing: spacing) {
                    ForEach(0..<numberOfPages, id: \.self) { page in
                        Circle()
                            .fill(activePage == page ? currentIndicatorColor : indicatorColor)
                            .frame(width: indicatorSize, height: indicatorSize)
                    }
                }
                .padding(.horizontal, (indicatorSize + spacing) / 2)
                .onChange(of: currentPage) { [previousPage = currentPage] nextPage in
                    withAnimation(animation) {
                        if previousPage < nextPage {
                            activePage += 1
                        } else {
                            activePage -= 1
                        }
                    }
                }
            }
        }
        .opacity(hidesForSinglePage && numberOfPages == 1 ? 0 : 1)
        .padding(.vertical, indicatorSize / 2)
        .overlay (
            PagingController(numberOfPages: numberOfPages, activePage: $currentPage)
        )
    }
    
    private func calculateSize(_ value: Int) -> CGFloat {
        let base = UInt(numberOfMainIndicators.halfValue)
        
        switch (activePage - displayedPosition - value).magnitude {
        case ...base:
            return indicatorSize
        case base + 1:
            return indicatorSize * 2 / 3
        case base + 2:
            return indicatorSize / 3
        default:
            return 0
        }
    }
}

public enum IndicatorType: Int {
    
    case three = 3
    case five = 5
    
    fileprivate var halfValue: Int {
        rawValue / 2
    }
    
    fileprivate func initialPosition(of value: Int, numberOfPages: Int) -> Int {
        
        switch self {
        case .three:
            switch value {
            case 0: -1
            case numberOfPages - 1: 1
            default: 0
            }
        case .five:
            switch value {
            case 0: -2
            case 1: -1
            case numberOfPages - 2: 1
            case numberOfPages - 1: 2
            default: 0
            }
        }
    }
}

public struct PagingControlConfig {
    
    public var indicatorSize: CGFloat
    public var spacing: CGFloat
    public var currentIndicatorColor: Color
    public var indicatorColor: Color
    public var numberOfMainIndicators: IndicatorType
    public var hidesForSinglePage: Bool
    public var animation: Animation
    
    fileprivate init() {
        self.indicatorSize = 8
        self.spacing = 8
        self.currentIndicatorColor = .primary
        self.indicatorColor = .gray.opacity(0.6)
        self.numberOfMainIndicators = .three
        self.hidesForSinglePage = false
        self.animation = .default
    }
}

private struct PagingController: UIViewRepresentable {
    
    let numberOfPages: Int
    @Binding var activePage: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let view = UIPageControl()
        view.numberOfPages = numberOfPages
        view.currentPage = activePage
        view.backgroundStyle = .minimal
        view.currentPageIndicatorTintColor = .clear
        view.pageIndicatorTintColor = .clear
        view.addTarget(context.coordinator, action: #selector(Coordinator.onPageUpdate(control:)), for: .valueChanged)
        return view
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = activePage
    }
    
    func makeCoordinator() -> Coordinator {
        .init(activePage: $activePage)
    }
    
    class Coordinator: NSObject {
        @Binding var activePage: Int
        
        init(activePage: Binding<Int>) {
            self._activePage = activePage
        }
        
        @objc
        func onPageUpdate(control: UIPageControl) {
            activePage = control.currentPage
        }
    }
}
