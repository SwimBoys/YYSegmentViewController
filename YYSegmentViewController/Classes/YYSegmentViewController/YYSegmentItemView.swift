//
//  YYSegmentItemView.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/25.
//

import UIKit

open class YYSegmentItemView: UIView {
    
    /// 配置文件
    public var config: YYSegmentConfig!
    /// 文本 label
    public let titleLabel = UILabel()
    /// 角标 label
    public let badgeValueLabel = UILabel()
    /// item 宽度
    var itemWidth: CGFloat = 0
    /// 指示标 view
    internal weak var indicatorView: YYIndicatorView?
    /// 角标
    public var index = 0
    /// 是否选中
    public var isSelected = false
    /// 大小百分比
    public var percent: CGFloat = 0
    /// title
    public var title: String = ""
    /// 当 title 和 badge 发生改变的时候，通知外部修改宽度
    public var itemWidthChanged: (() -> Void)?
    
    /// item
    public var tabBarItem: UITabBarItem? {
        didSet{
            tabBarItem?.addObserver(self, forKeyPath: badgeValueObserverKeyPath, options: [.new], context: nil)
            tabBarItem?.addObserver(self, forKeyPath: titleObserverKeyPath, options: [.new], context: nil)
        }
    }
    /// badge 值变化
    private let badgeValueObserverKeyPath = "badgeValue"
    /// title 值变化
    private let titleObserverKeyPath = "title"
    /// 根据 YYItemViewWidthChangeStyle 计算 item 的宽度
    public var widthStyle = YYItemViewWidthChangeStyle.equalToTitleWidth(margin: 10) {
        didSet{
            switch widthStyle {
            case .equalToTitleWidth(let margin):
                let titleLableWidth = self.title.YYGetStrSize(font: config.itemTitleFont * config.itemTitleSelectedScale, w: 1000, h: 1000).width
                itemWidth = titleLableWidth + getBadgeWidth() + margin
            case .stationary(let margin):
                itemWidth = margin
                break
            }
        }
    }
    
    /// 初始化
    /// - Parameters:
    ///   - frame: frame
    ///   - config: 配置文件
    public init(frame: CGRect, config: YYSegmentConfig) {
        super.init(frame: frame)
        self.config = config
        initSubView()
    }
    
    func initSubView() {
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: config.itemTitleFont)
        titleLabel.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
        
        badgeValueLabel.backgroundColor = config.itemBadgeBackgroundColor
        badgeValueLabel.textAlignment = .center
        badgeValueLabel.textColor = config.itemBadgeTitleColor
        badgeValueLabel.font = UIFont.systemFont(ofSize: config.itemBadgeTitleFont)
        badgeValueLabel.frame = CGRect.init(x: 0, y: 0, width: config.itemBadgeSize.width, height: config.itemBadgeSize.width)
        badgeValueLabel.center = CGPoint.init(x: bounds.width - 10, y: 10)
        badgeValueLabel.isHidden = true
        addSubview(badgeValueLabel)
        self.bringSubviewToFront(badgeValueLabel)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tabBarItem?.removeObserver(self, forKeyPath: titleObserverKeyPath)
        tabBarItem?.removeObserver(self, forKeyPath: badgeValueObserverKeyPath)
    }
}

// MARK: - title 和 badge 变化监听
extension YYSegmentItemView {
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if  keyPath ==  badgeValueObserverKeyPath {
            badgeValueChange(badgeValue: tabBarItem?.badgeValue ?? "")
        } else if keyPath == titleObserverKeyPath {
            titleChange(title: tabBarItem?.title ?? "")
        }
        switch config.itemWidthStyle {
        case .stationary(baseWidth: _):
            titleLabel.sizeToFit()
            badgeValueLabel.sizeToFit()
            break
        case .equalToTitleWidth(margin: _):
            self.widthStyle = config.itemWidthStyle
        }
        itemWidthChanged?()
    }
    
    public func titleChange(title: String) {
        self.title = title
        titleLabel.text = title
        let size = self.title.YYGetStrSize(font: config.itemTitleFont * config.itemTitleSelectedScale, w: 1000, h: 1000)
        titleLabel.frame.size = size
    }
    
    public func badgeValueChange(badgeValue: String) {
        
    }
}

// MARK: - badge 相关
extension YYSegmentItemView {
    /// 返回 badge 的宽度
    public func getBadgeWidth() -> CGFloat {
        var width: CGFloat = 0
        if tabBarItem?.badgeValue == nil {
            width = 0
        } else {
            if config.itemBadgeStyle == .dots {
                width = config.itemBadgeSize.width
            } else if config.itemBadgeStyle == .round {
                var badgeValueStr = tabBarItem?.badgeValue
                if let badgeValue = badgeValueStr, let intValue = Int(badgeValue) {
                    if intValue > config.itemBadgeValueMaxNum {
                        badgeValueStr = "\(config.itemBadgeValueMaxNum)+"
                    }
                }
                let badgeSize = badgeValueStr?.YYGetStrSize(font: config.itemBadgeTitleFont, w: 1000, h: 1000)
                let badgeWidth = max(badgeSize?.width ?? 0, badgeSize?.height ?? 0)
                width = badgeWidth + config.itemBadgeStyleRoundMargin.leftRightMargin
            } else {
                var badgeValueStr = tabBarItem?.badgeValue
                if config.itemBadgeStyle == .right {
                    if let badgeValue = badgeValueStr, let intValue = Int(badgeValue) {
                        if intValue > config.itemBadgeValueMaxNum {
                            badgeValueStr = "\(config.itemBadgeValueMaxNum)+"
                        }
                    }
                }
                width = badgeValueStr?.YYGetStrSize(font: config.itemBadgeTitleFont, w: 1000, h: 1000).width ?? 0
            }
        }
        return width + config.itemBadgeValueLabelOffset.x
    }
    
    /// 设置 titleLabel 和 badgeValueLabel 的 center
    internal func layoutTitleLabelAndBadgeLabel() {
        var badgeValueStr = tabBarItem?.badgeValue
        if (badgeValueStr == nil) || (badgeValueStr == "") || (badgeValueStr == "0") {
            badgeValueLabel.isHidden = true
            badgeValueLabel.text = ""
            titleLabel.center = CGPoint.init(x: bounds.width / 2, y: bounds.height / 2 + config.itemTitleCenterOffsetY)
        } else {
            badgeValueLabel.isHidden = false
            if config.itemBadgeStyle != .custom {
                if let badgeValue = badgeValueStr, let intValue = Int(badgeValue) {
                    if intValue > config.itemBadgeValueMaxNum {
                        badgeValueStr = "\(config.itemBadgeValueMaxNum)+"
                    }
                }
            }
            badgeValueLabel.text = badgeValueStr
            badgeValueLabel.sizeToFit()
            
            var badgeValueLabelFrame = badgeValueLabel.frame
            if config.itemBadgeStyle == .dots {
                badgeValueLabelFrame.size = config.itemBadgeSize
                badgeValueLabel.text = ""
            } else if config.itemBadgeStyle == .round {
                let badgeWidth = badgeValueStr?.YYGetStrSize(font: config.itemBadgeTitleFont, w: 1000, h: 1000).width ?? 0
                badgeValueLabelFrame.size.width = badgeWidth + config.itemBadgeStyleRoundMargin.leftRightMargin
                badgeValueLabelFrame.size.height += config.itemBadgeStyleRoundMargin.topBottmMargin
                badgeValueLabelFrame.size.width = max(badgeValueLabelFrame.width, badgeValueLabelFrame.height)
            } else {
                badgeValueLabel.backgroundColor = .clear
                badgeValueLabelFrame.size = (badgeValueLabel.text ?? "").YYGetStrSize(font: config.itemBadgeTitleFont, w: 1000, h: 1000)
            }
            badgeValueLabel.frame = badgeValueLabelFrame
            badgeValueLabel.layer.cornerRadius = badgeValueLabel.bounds.height / 2
            badgeValueLabel.clipsToBounds = true
            
            
            let badgeValueLabelMaxWidth: CGFloat = config.itemBadgeValueLabelOffset.x + badgeValueLabelFrame.width
            /// 文本 右边间距 够放角标
            if ((self.bounds.width - titleLabel.bounds.width) / 2) > badgeValueLabelMaxWidth {
                titleLabel.center = CGPoint.init(x: bounds.width / 2, y: bounds.height / 2 + config.itemTitleCenterOffsetY)
            } else {
                if self.bounds.width - badgeValueLabelMaxWidth - titleLabel.bounds.width - 4 < 0 {
                    titleLabel.center = CGPoint.init(x: bounds.width / 2, y: bounds.height / 2 + config.itemTitleCenterOffsetY)
                } else {
                    let x = (self.bounds.width - badgeValueLabelMaxWidth - 4) / 2
                    titleLabel.center = CGPoint(x: x, y: bounds.height / 2 + config.itemTitleCenterOffsetY)
                }
            }
            if config.itemBadgeStyle == .dots || config.itemBadgeStyle == .round {
                badgeValueLabel.center = CGPoint.init(x: titleLabel.frame.maxX + config.itemBadgeValueLabelOffset.x + badgeValueLabelFrame.width / 2, y: titleLabel.frame.minY + config.itemBadgeValueLabelOffset.y + badgeValueLabelFrame.height / 2)
            } else {
                badgeValueLabel.center = CGPoint.init(x: titleLabel.frame.maxX + config.itemBadgeValueLabelOffset.x + badgeValueLabelFrame.width / 2, y: titleLabel.center.y)
            }
        }
    }
}

// MARK: - label 和 badgeValueLabel 变化
extension YYSegmentItemView {
    override open func layoutSubviews() {
        super.layoutSubviews()
        titleLabelCalculation()
        layoutTitleLabelAndBadgeLabel()
    }
    
    /// label 百分比变化
    /// - Parameter percent: percent
    public func percentChange(percent: CGFloat) {
        if percent == 1 {
            self.isSelected = true
        } else if percent == 0 {
            self.isSelected = false
        }
        self.percent = percent
        titleLabelCalculation()
    }
    
    /// titleLabel 改变
    public func titleLabelCalculation() {
        let percentConvert = self.percentConvert()
        titleLabel.textColor = interpolationColorFrom(fromColor: config.itemTitleNormalColor, toColor: config.itemTitleSelectColor, percent: percentConvert)
        let scale = 1 + (config.itemTitleSelectedScale - 1) * percentConvert
        let font = UIFont.boldSystemFont(ofSize: config.itemTitleFont * scale)
        titleLabel.font = font
        let size = self.title.YYGetStrSize(font: config.itemTitleFont * config.itemTitleSelectedScale, w: 1000, h: 1000)
        titleLabel.frame.size.width = size.width
    }
    
    /// 根据 YYSegmentItemViewSelectedStyle 返回 title 文本变化的百分比
    /// - Returns: 百分比
    public func percentConvert() -> CGFloat {
        switch config.itemViewSegmentSelectedStyle {
        case .gradient:
            return percent
        case .mid:
            if percent >= 0.5 {
                return 1
            }else{
                return 0
            }
        case .totalSelected:
            if isSelected == true {
                return 1
            }else{
                return 0
            }
        }
    }
}

public func interpolationColorFrom(fromColor: UIColor, toColor: UIColor, percent: CGFloat) -> UIColor {
    var fromR:CGFloat = 0
    var fromG:CGFloat = 0
    var fromB:CGFloat = 0
    var fromA:CGFloat = 0
    fromColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
    
    var toR:CGFloat = 0
    var toG:CGFloat = 0
    var toB:CGFloat = 0
    var toA:CGFloat = 0
    toColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
    
    let red = interpolationFrom(from: fromR, to: toR, percent: percent)
    let green = interpolationFrom(from: fromG, to: toG, percent: percent)
    let blue = interpolationFrom(from: fromB, to: toB, percent: percent)
    let alpha = interpolationFrom(from: fromA, to: toA, percent: percent)
    return UIColor.init(red: red, green: green, blue: blue, alpha: alpha)
}

// MARK: - 返回字符串的 size
extension String {
    internal func YYGetStrSize(font: CGFloat, w: CGFloat, h: CGFloat) -> CGSize {
        let strSize = (self as NSString).boundingRect(with: CGSize(width: w, height: h), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font)], context: nil).size
        return CGSize(width: ceil(strSize.width), height: ceil(strSize.height))
    }
}
