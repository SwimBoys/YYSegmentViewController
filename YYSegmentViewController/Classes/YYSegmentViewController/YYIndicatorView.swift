//
//  YYIndicatorView.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

@objc public protocol YYIndicatorViewDelegate : NSObjectProtocol {
    @objc optional func indicatorView(indicatorView: YYIndicatorView, percent: CGFloat)
}

open class YYIndicatorView: UIView {
    
    /// 配置文件
    public var config: YYSegmentConfig!
    /// 容器视图
    public var contentView = UIView()
    /// 代理
    public weak var delegate: YYIndicatorViewDelegate?
    /// 设置位置
    public var centerYGradientStyle = YYIndicatorViewCenterYGradientStyle.bottom(margin: 0) {
        didSet{
            if let selfSuperView = self.superview {
                var selfCenter = self.center
                switch centerYGradientStyle {
                case .top(let margin):
                    selfCenter.y = margin + bounds.height / 2
                case .center:
                    selfCenter.y = selfSuperView.bounds.height / 2
                case .bottom(let margin):
                    selfCenter.y = selfSuperView.bounds.height - margin - bounds.height / 2
                }
                self.center = selfCenter
            }
        }
    }
    /// 根据样式设置宽度
    public var widthChangeStyle = YYIndicatorViewWidthChangeStyle.stationary(baseWidth: 10) {
        didSet{
            var targetWidth = self.bounds.width
            switch widthChangeStyle {
            case .equalToItemWidth:
                return
            case .itemWidthScaleChange(let baseWidth, _):
                targetWidth = baseWidth
            case .stationary(let baseWidth):
                targetWidth = baseWidth
            }
            var selfBounds = self.bounds
            selfBounds.size.width = targetWidth
            self.bounds = selfBounds
        }
    }
    /// 根据 YYIndicatorViewShapeStyle 设置形状样式
    public var shapeStyle = YYIndicatorViewShapeStyle.custom {
        didSet{
            self.layer.contents = nil
            switch shapeStyle {
            case .custom:
                break
            case .background(let color, let img):
                self.centerYGradientStyle = .center
                self.widthChangeStyle = config.itemIndicatorViewWidthChangeStyle// .equalToItemWidth(margin: 0)
                self.backgroundColor = color
                self.layer.contents = img?.cgImage
                
                var selfFrame = self.frame
                selfFrame.size.height = superview?.bounds.height ?? selfFrame.height
                self.frame = selfFrame
                self.autoresizingMask = [.flexibleHeight]
            case .crossBar(let widthChangeStyle, let height):
                self.widthChangeStyle = widthChangeStyle
                self.centerYGradientStyle = .bottom(margin: 0)
                var selfBounds = self.bounds
                selfBounds.size.height = height
                self.bounds = selfBounds
            case .triangle(let size, let color):
                self.widthChangeStyle = .stationary(baseWidth: size.width)
                self.centerYGradientStyle = .bottom(margin: 0)
                var selfBounds = self.bounds
                selfBounds.size = size
                self.bounds = selfBounds
                
                let trianglePath = UIBezierPath()
                trianglePath.move(to: CGPoint.init(x: size.width/2, y: 0))
                trianglePath.addLine(to: CGPoint.init(x: size.width, y: size.height))
                trianglePath.addLine(to: CGPoint.init(x: 0, y: size.height))
                trianglePath.close()
                
                let triangleShape = CAShapeLayer()
                triangleShape.path = trianglePath.cgPath
                triangleShape.lineWidth = 0
                triangleShape.fillColor = color.cgColor
                contentView.layer.addSublayer(triangleShape)
                
                self.backgroundColor = UIColor.clear
                self.contentView.backgroundColor = UIColor.clear
            case .ellipse(let widthChangeStyle, let height, let shadowColor, let alpha):
                self.widthChangeStyle = widthChangeStyle
                self.centerYGradientStyle = .center
                var selfBounds = self.bounds
                selfBounds.size.height = height
                self.bounds = selfBounds
                self.layer.cornerRadius = height / 2
                if shadowColor != nil {
                    self.layer.shadowColor = shadowColor!.cgColor;
                    self.layer.shadowRadius = 3;
                    self.layer.shadowOffset = CGSize.init(width: 3, height: 4);
                    self.layer.shadowOpacity = 0.6;
                }
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(alpha)
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
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    /// 初始化
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        addSubview(contentView)
//        contentView.frame = bounds
//        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - 自身宽度的变化
extension YYIndicatorView {
    /// 滚动时变化宽度
    internal func reloadLayout(leftItemView: YYSegmentItemView, rightItemView: YYSegmentItemView) {
        var selfCenter = self.center
        let leftMargin: CGFloat = leftItemView.frame.minX + leftItemView.titleLabel.center.x
        let rightMargin: CGFloat = rightItemView.frame.minX + rightItemView.titleLabel.center.x
        
        selfCenter.x = interpolationFrom(from: leftMargin, to: rightMargin, percent: rightItemView.percent)
        self.center = selfCenter
        //bounds.width
        var targetWidth = self.bounds.width
        switch widthChangeStyle {
        case .equalToItemWidth(let margin):
            let leftItemWidth = leftItemView.titleLabel.bounds.width
            let rightItemWidth = rightItemView.titleLabel.bounds.width
            targetWidth = interpolationFrom(from: leftItemWidth, to: rightItemWidth, percent: rightItemView.percent)
            targetWidth -= 2 * margin
        case .itemWidthScaleChange(let baseWidth, let changeWidth):
            let newPercent = 1 - abs(0.5 - leftItemView.percent) * 2   //变化范围（0....1.....0）
            let minX = leftItemView.center.x - baseWidth / 2
            let maxX = rightItemView.center.x - baseWidth / 2
            targetWidth = newPercent * (maxX - minX - changeWidth) + baseWidth
            
        case .stationary(let baseWidth):
            targetWidth = baseWidth
        }
        var selfBounds = self.bounds
        selfBounds.size.width = targetWidth
        self.bounds = selfBounds
        
        delegate?.indicatorView?(indicatorView: self, percent: leftItemView.percent)
    }
    
    /// 最终停留不动下来的宽度
    internal func finalWidthOn(itemView: YYSegmentItemView) -> CGFloat {
        let itemViewWidth = itemView.frame.width
        var width:CGFloat = 0
        switch widthChangeStyle {
        case .equalToItemWidth(let margin):
            width = itemViewWidth - 2 * margin
        case .itemWidthScaleChange(let baseWidth, _):
            width = baseWidth
        case .stationary(let baseWidth):
            width = baseWidth
        }
        return width
    }
}

public func interpolationFrom(from: CGFloat, to: CGFloat, percent: CGFloat) -> CGFloat {
    let ratio = max(0, min(1, percent))
    return from + (to - from) * ratio
}
