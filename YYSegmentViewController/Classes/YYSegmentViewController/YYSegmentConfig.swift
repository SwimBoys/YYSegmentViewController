//
//  YYSegmentConfig.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

/// 分段控件的位置
public enum YYSegmentedCtontrolPositionType {
    /// 在导航条上面的（size为上边 itemview 的 frame，navigationBarHeight 为 bar 的高度）
    case nav(size:CGSize, navigationBarHeight: CGFloat)
    /// 在顶部
    case top
    /// 在底部
    case bottom
    /// 自定义位置
    /// segmentCtl 和 container 是添加到 containerScr 上的
    /// （containerScrFrame 为最底部ScrollView的frame,  segmentCtlFrame 为上边 itemview 的 frame，containerFrame 为下边 pageView 的 frame）
    case customFrame(containerScrFrame: CGRect, segmentCtlFrame:CGRect, containerFrame:CGRect)
}

/// 下拉刷新控件的位置
public enum YYDragRefreshType {
    /// 整体下拉
    case container
    /// 列表下拉
    case list
}

/// item 宽度变化样式
public enum YYItemViewWidthChangeStyle {
    /// 根据文本大小展示(距离两边的间距)
    case equalToTitleWidth(margin: CGFloat)
    /// 固定宽度样式
    case stationary(baseWidth: CGFloat)
}

/// 指示器宽度变化样式
public enum YYIndicatorViewWidthChangeStyle {
    /// 跟Item 文本等宽样式
    case equalToItemWidth(margin: CGFloat)
    /// item 宽度比例变化
    /// baseWidth 为最终显示的大小
    /// changeWidth 值越大，变化的越大
    case itemWidthScaleChange(baseWidth: CGFloat, changeWidth: CGFloat)
    /// 固定宽度样式
    case stationary(baseWidth: CGFloat)
}

/// 指示器中心位置
public enum YYIndicatorViewCenterYGradientStyle {
    /// 在正中心
    case center
    /// 在顶部，跟顶部间距为margin
    case top(margin: CGFloat)
    /// 在底部，跟底部间距为margin
    case bottom(margin: CGFloat)
}

/// 指示器形状样式: 这里只是给定了几种常见的样式
public enum YYIndicatorViewShapeStyle {
    /// 自定义类型,不做任何处理，由外部定义这个view的宽高
    case custom
    /// 三角形
    case triangle(size:CGSize, color:UIColor)
    /// 椭圆
    case ellipse(widthChangeStyle: YYIndicatorViewWidthChangeStyle, height: CGFloat, shadowColor:UIColor?, alpha: CGFloat = 1)
    /// 横杆
    case crossBar(widthChangeStyle: YYIndicatorViewWidthChangeStyle, height:CGFloat)
    /// 背景
    case background(color: UIColor, img: UIImage?)
}

/// 选中的 Item 变化位置
public enum YYSegmentItemViewSelectedStyle {
    /// 从中间
    case mid
    /// 从一开始 0...1
    case gradient
    /// 完全选中才变化
    case totalSelected
}

/// item 角标样式
public enum YYItemViewBadgeStyle {
    /// 圆点
    case dots
    /// 圆形
    case round
    /// 右边
    case right
    /// 自定义文本
    case custom
}


class YYSegmentConfig: NSObject {
    
    // MARK: - 显示的控制器
    /// 是否继承 YYSegmentViewController
    var isInherit: Bool = false
    /// 显示的控制器数组
    var containerControllerArr: [UIViewController] = []
    /// 预加载范围，当前view前面几个，后面几个
    var preLoadRange = 0...0
    
    // MARK: - 上边分段控制器的配置
    /// 分段控制器的背景色，默认白色
    var segmentBackgroundColor: UIColor = .white
    /// 分段控制器的高度，默认为50
    var segmentControlHeight: CGFloat = 50
    /// 分段控制器的宽度，默认为屏幕宽
    var segmentControlWidth: CGFloat = UIScreen.main.bounds.width
    /// 分段控制器的位置，默认在顶部
    var segmentControlPositionType: YYSegmentedCtontrolPositionType = .top
    /// 是否显示竖向滚动指示器，默认隐藏
    var showsVerticalScrollIndicator: Bool = false
    /// 是否显示横向滚动指示器，默认隐藏
    var showsHorizontalScrollIndicator: Bool = false
    /// 分段控制器底部分割线是否显示，默认不显示
    var isShowBottomSeparatorLineView = false
    /// 分段控制器底部分割线颜色，默认灰色
    var bottomSeparatorLineViewBackgroundColor = UIColor.lightGray
    /// 分段控制器底部分割线线宽，默认 1
    var bottomSeparatorLineViewHeight: CGFloat = 1 / UIScreen.main.scale
    /// 下拉刷新控件的位置，默认是列表下拉
    public var refreshType = YYDragRefreshType.list
    /// 分段控制器头部view
    public var headView: UIView?
    /// 当你往下滑动需要隐藏navigationBar, 滑动到顶部需要显示 navigationBar，此值就需要设置为 navigationBar的高度 + 状态栏的高度，其余设置为0即可
    var minimumHeight: CGFloat = 0
    
    
    // MARK: - item的配置
    /// item间距，默认0
    var itemSpacing: CGFloat = 0
    /// item默认选中角标，默认0
    var itemDefaultSelectedIndex: NSInteger = 0
    /// item 底部ScrollView的 contentInset
    var itemContentInset = UIEdgeInsets.zero
    /// item 宽度类型，默认是根据文本展示（左右各10）
    var itemWidthStyle: YYItemViewWidthChangeStyle = .equalToTitleWidth(margin: 10)
    /// item 之间分割线是否显示，默认不显示
    var isShowItemSeparatorLineView = false
    /// item 之间分割线颜色，默认 灰色
    var itemSeparatorLineColor = UIColor.lightGray
    /// item 之间分割线宽度，默认 1
    var itemSeparatorLineWidth: CGFloat = 1 / UIScreen.main.scale
    /// item 之间分割线距离上下的距离，默认都是 0
    var itemSeparatorLineTopBottomMargin:(top: CGFloat, bottom: CGFloat) = (0, 0)
    /// item 文本默认颜色，默认 灰色
    var itemTitleNormalColor: UIColor = .lightGray
    /// item 文本选中颜色，默认 黑色
    var itemTitleSelectColor: UIColor = .black
    /// item 文本中心偏移距离
    var itemTitleCenterOffsetY: CGFloat = 0
    /// item 文本font，默认 12
    var itemTitleFont: CGFloat = 12
    /// item 选中过程过度大小
    var itemTitleSelectedScale: CGFloat = 1.2
    /// item 选中的变化位置，默认是逐渐变化
    var itemViewSegmentSelectedStyle: YYSegmentItemViewSelectedStyle = .gradient
    // MARK: - item 指示标
    /// item 指示标背景色，默认黑色
    var itemIndicatorViewBackgroundColor: UIColor = .black
    /// item 指示标的位置（中间、偏上、偏下），默认是在底部
    var itemIndicatorViewCenterYGradientStyle: YYIndicatorViewCenterYGradientStyle = .bottom(margin: 0)
    /// item 指示标宽度的类型，默认是固定宽度，为 10
    var itemIndicatorViewWidthChangeStyle: YYIndicatorViewWidthChangeStyle = .stationary(baseWidth: 10)
    /// item 指示标的类型，默认是跟item 文本等宽的横杆，高度为 3
    /// 当设置了此选项中YYIndicatorViewWidthChangeStyle，上边的itemIndicatorViewWidthChangeStyle 就不再起作用
    var itemIndicatorViewShapeStyle: YYIndicatorViewShapeStyle = .crossBar(widthChangeStyle: .equalToItemWidth(margin: 0), height: 3)
        
    // MARK: - item右上角角标 数字或者红点
    /// 角标是否显示
    var isShowItemBadge = false
    /// 角标样式，默认是圆点
    var itemBadgeStyle: YYItemViewBadgeStyle = .dots
    /// 角标文本颜色，默认白色
    var itemBadgeTitleColor: UIColor = .white
    /// 角标背景颜色，默认红色
    var itemBadgeBackgroundColor: UIColor = .red
    /// 角标字体大小，默认12
    var itemBadgeTitleFont: CGFloat = 12
    /// 角标最大值，默认 99
    var itemBadgeValueMaxNum: NSInteger = 99
    /// 角标style为dots和round时， 偏离item label 右上角，当style为 right 时，偏离文本的右边，y 不起作用
    var itemBadgeValueLabelOffset = CGPoint.init(x: 0, y: 0)
    /// 角标style为圆点时， size默认（5，5）
    var itemBadgeSize = CGSize(width: 5, height: 5)
    /// 角标style为round时， 角标文本距离上下左右的间距
    var itemBadgeStyleRoundMargin: (leftRightMargin: CGFloat, topBottmMargin: CGFloat) = (4, 4)
}
