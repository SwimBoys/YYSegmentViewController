//
//  YYSegmentedView.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

@objc public protocol YYSegmentedViewDelegate : NSObjectProtocol {
    /// 点击ItemView回调
    @objc optional func segMegmentCtlView(segMegmentCtlView: YYSegmentedView, clickItemAt sourceItemView: YYSegmentItemView, to destinationItemView: YYSegmentItemView)
    /// 点击ItemView回调， 可以控制是否跳转
    @objc optional func segMegmentCtlView(segMegmentCtlView: YYSegmentedView, sourceItemView: YYSegmentItemView, shouldChangeTo destinationItemView: YYSegmentItemView) -> Bool
    /// 滚动ContentView
    @objc optional func segMegmentCtlView(segMegmentCtlView: YYSegmentedView, dragToScroll leftItemView: YYSegmentItemView, rightItemView: YYSegmentItemView)
    /// 最终滚动停留下来的位置
    @objc optional func segMegmentCtlView(segMegmentCtlView: YYSegmentedView, dragToSelected itemView: YYSegmentItemView)
}

open class YYSegmentedView: UIView {
    
    /// 配置文件
    public var config: YYSegmentConfig!
    /// 底部 page 偏移监听
    private let associateScrollerViewObserverKeyPath = "contentOffset"
    /// 底部供其滑动的ScrollView
    public  let segMegmentScrollerView = UIScrollView(frame: CGRect.zero)
    /// 底部分割线
    public  let bottomSeparatorLineView = UIView()
    /// 底部指示标
    public var indicatorView: YYIndicatorView!
    /// 外部关联的ScrollView，就是底部装控制器的ScrollView
    public weak var associateScrollerView: UIScrollView? {
        didSet {
            associateScrollerView?.addObserver(self, forKeyPath: associateScrollerViewObserverKeyPath, options: [.new,.old], context: nil)
        }
    }
    
    internal var tabBarItems: [UITabBarItem]!
    /// item 之间的分割view
    public  var separatorViews = [UIView]()
    /// 滚动到的位置 所占 百分比
    public  var totalPercent: CGFloat = 0
    /// 点击是否有动画
    public var clickAnimation = true
    /// 当前显示的 item
    public private (set) var currentSelectedItemView: YYSegmentItemView!
    /// 左边的item
    public private (set) var leftItemView: YYSegmentItemView!
    /// 右边的item
    public private (set) var rightItemView: YYSegmentItemView!
    /// item 集合
    public private (set) var itemViews = [YYSegmentItemView]()
    /// item 和 分割线 集合
    private var itemAndSeparatorViews = [(itemView: YYSegmentItemView, separatorView: UIView)]()
    /// 代理
    public weak var delegate: YYSegmentedViewDelegate?
    
    
    /// 初始化方法
    /// - Parameters:
    ///   - frame: frame
    ///   - tabBarItems: tabBarItems
    ///   - config: 配置文件
    public init(frame: CGRect, tabBarItems: [UITabBarItem], config: YYSegmentConfig) {
        super.init(frame: frame)
        self.config = config
        self.tabBarItems = tabBarItems
        initSubviews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 点击 item
    /// - Parameters:
    ///   - Index: Index
    ///   - animation: animation
    public func selected(at Index:NSInteger, animation: Bool)  {
        if let targetItemView = getItemView(atIndex: Index),
            let currentSelectedItemView = currentSelectedItemView,
            targetItemView != currentSelectedItemView {
            let preAnimation = clickAnimation
            clickAnimation = animation
            checkOutItemView(sourceItemView: currentSelectedItemView, destinationItemView: targetItemView)
            clickAnimation = preAnimation
        }
    }
    
    deinit {
        associateScrollerView?.removeObserver(self, forKeyPath: associateScrollerViewObserverKeyPath)
    }
}

// MARK: - init
extension YYSegmentedView {
    
    /// 刷新数据和页面
    public func reloadData() {
        removeItemViews()
        addItemViews()
        setDefaultSelectedAtIndexStatu()
    }
    
    func initSubviews() {
        
        self.backgroundColor = config.segmentBackgroundColor
        if #available(iOS 11.0, *) {
            segMegmentScrollerView.contentInsetAdjustmentBehavior = .never
        }
        segMegmentScrollerView.backgroundColor = UIColor.clear
        segMegmentScrollerView.frame = bounds
        segMegmentScrollerView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        segMegmentScrollerView.showsHorizontalScrollIndicator = false
        segMegmentScrollerView.showsVerticalScrollIndicator = false
        segMegmentScrollerView.bounces = false
        addSubview(segMegmentScrollerView)

        indicatorView = YYIndicatorView(frame: CGRect.zero, config: config)
        indicatorView.backgroundColor = config.itemIndicatorViewBackgroundColor
        segMegmentScrollerView.addSubview(indicatorView)
        
        bottomSeparatorLineView.backgroundColor = config.bottomSeparatorLineViewBackgroundColor
        bottomSeparatorLineView.frame = CGRect.init(x: 0, y: bounds.height - config.bottomSeparatorLineViewHeight, width: bounds.width, height: config.bottomSeparatorLineViewHeight)
        bottomSeparatorLineView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addSubview(bottomSeparatorLineView)
        bottomSeparatorLineView.isHidden = !config.isShowBottomSeparatorLineView
    }

    /// 删除原有视图
    private func removeItemViews() {
        for subView in segMegmentScrollerView.subviews{
            if (subView != indicatorView) {
                subView.removeFromSuperview()
            }
        }
        itemViews.removeAll()
        itemAndSeparatorViews.removeAll()
    }
    
    /// 添加视图
    private func addItemViews() {
        for (index, tabBarItem) in tabBarItems.enumerated() {
            /// ItemView
            let segmentCtlItemView = YYSegmentItemView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: bounds.height), config: config)
            segmentCtlItemView.tabBarItem = tabBarItem
            segmentCtlItemView.titleChange(title: tabBarItem.title ?? "")
            segmentCtlItemView.percentChange(percent: 0)
            segmentCtlItemView.index = index
            segmentCtlItemView.indicatorView = indicatorView
            segmentCtlItemView.widthStyle = config.itemWidthStyle
            segmentCtlItemView.itemWidthChanged = { [weak self, weak segmentCtlItemView] in
                guard let this = self, let item = segmentCtlItemView else {
                    return
                }
                /// 更新frame
                this.reLayoutItemViews()
                item.layoutSubviews()
                /// 更新指示器位置
                this.indicatorView.reloadLayout(leftItemView: this.leftItemView,
                                                 rightItemView: this.rightItemView)
                this.segmentScrollerViewSrollerToCenter(itemView: item, animated: true)
            }
            segmentCtlItemView.tag = index
            segMegmentScrollerView.addSubview(segmentCtlItemView)
            itemViews.append(segmentCtlItemView)
            /// item 添加点击事件
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(segmentItemClick(gesture:)))
            segmentCtlItemView.addGestureRecognizer(tapGesture)
            /// 分割线
            let separatorView = UIView()
            reloadOneSeparatorView(separatorView: separatorView)
            separatorViews.append(separatorView)
            segMegmentScrollerView.addSubview(separatorView)

            let itemAndSeparatorView = (segmentCtlItemView, separatorView)
            itemAndSeparatorViews.append(itemAndSeparatorView)
        }
        indicatorView.widthChangeStyle = config.itemIndicatorViewWidthChangeStyle
        indicatorView.shapeStyle = config.itemIndicatorViewShapeStyle
        reLayoutItemViews()
    }
    
    /// 重新布局 item 和 分割线 的位置
    private func reLayoutItemViews() {
        var lastItemView: YYSegmentItemView? = nil
        for (offset: _, element: (itemView: segmentCtlItemView, separatorView: separatorView)) in itemAndSeparatorViews.enumerated() {
            var segmentCtlItemViewFrame = segmentCtlItemView.frame
            segmentCtlItemViewFrame.size.width = segmentCtlItemView.itemWidth
            segmentCtlItemViewFrame.size.height = self.bounds.height
            if let lastItemView = lastItemView {
                segmentCtlItemViewFrame.origin.x = lastItemView.frame.maxX + config.itemSpacing
            }
            segmentCtlItemViewFrame.origin.y = (bounds.height - segmentCtlItemViewFrame.size.height) / 2
            segmentCtlItemView.frame = segmentCtlItemViewFrame
            
            /// 分割线
            if lastItemView != nil {
                separatorView.center.x = (lastItemView!.frame.maxX + segmentCtlItemView.frame.minX)/2
            } else {
                separatorView.isHidden = true
            }
            lastItemView = segmentCtlItemView
        }
        segMegmentScrollerView.contentSize = CGSize.init(width: lastItemView?.frame.maxX ?? bounds.width, height: bounds.height)
        segMegmentScrollerView.contentInset = config.itemContentInset
    }

    /// 初始化设置状态和位置
    private func setDefaultSelectedAtIndexStatu() {
        guard tabBarItems.count > 0 else {
            return
        }
        if let defaultSelectedItemView = getItemView(atIndex: config.itemDefaultSelectedIndex) {
            defaultSelectedItemView.percentChange(percent: 1)
            currentSelectedItemView = defaultSelectedItemView
            rightItemView = defaultSelectedItemView
            leftItemView = defaultSelectedItemView
            
            segmentScrollerViewSrollerToCenter(itemView: defaultSelectedItemView, animated: false)
            /// 设置 pageview 的偏移量
            if let associateScrollerView = associateScrollerView {
                let offsetX = CGFloat(config.itemDefaultSelectedIndex) * associateScrollerView.bounds.width
                associateScrollerView.setContentOffset(CGPoint.init(x: offsetX, y: 0), animated: false)
            }
            
            indicatorView.centerYGradientStyle = config.itemIndicatorViewCenterYGradientStyle
            defaultSelectedItemView.layoutSubviews()
            indicatorView.reloadLayout(leftItemView: defaultSelectedItemView, rightItemView: defaultSelectedItemView)
            totalPercent = 1.0 / CGFloat(tabBarItems.count)
        }
    }
    
    private func getItemView(atIndex: NSInteger) -> YYSegmentItemView? {
        if atIndex < 0 || atIndex >= itemViews.count {
            return nil
        }
        return itemViews[atIndex]
    }
    
    /// 设置 item 之间分割线
    private func reloadOneSeparatorView(separatorView: UIView) {
        var separatorViewCenter = separatorView.center
        separatorView.frame = CGRect.init(x: 0, y: config.itemSeparatorLineTopBottomMargin.top, width: config.itemSeparatorLineWidth, height: bounds.height - config.itemSeparatorLineTopBottomMargin.top - config.itemSeparatorLineTopBottomMargin.bottom)
        separatorViewCenter.y = separatorView.center.y
        separatorView.center = separatorViewCenter
        separatorView.backgroundColor = config.itemSeparatorLineColor
        separatorView.isHidden = !config.isShowItemSeparatorLineView
    }
}

// MARK: - item 点击事件处理
extension YYSegmentedView {
    
    @objc func segmentItemClick(gesture: UITapGestureRecognizer) {
        if let sourceItemView = currentSelectedItemView, let destinationItemView = gesture.view as? YYSegmentItemView {
            checkOutItemView(sourceItemView: sourceItemView, destinationItemView: destinationItemView)
        }
    }
    
    private func checkOutItemView(sourceItemView: YYSegmentItemView, destinationItemView: YYSegmentItemView) {
        /// 询问代理点击是否切换
        let shouldCheckOut = delegate?.segMegmentCtlView?(segMegmentCtlView: self, sourceItemView: sourceItemView, shouldChangeTo: destinationItemView)
        if shouldCheckOut != true && shouldCheckOut != nil {
            return
        }

        /// 点击的是当前的
        if sourceItemView == destinationItemView {
            return
        }
        
        /// 有些类型要处理点击的情况
        delegate?.segMegmentCtlView?(segMegmentCtlView: self, clickItemAt: sourceItemView, to: destinationItemView)
        
        /// ItemView
        checkOutItemViewAction(sourceItemView: sourceItemView, destinationItemView: destinationItemView)
        
        /// associateScrollerView  响应
        checkOutItemContentViewAction(sourceItemView: sourceItemView, destinationItemView: destinationItemView)
        
        /// segMegmentScrollerView响应
        segmentScrollerViewSrollerToCenter(itemView: destinationItemView, animated: clickAnimation)
        
        /// 指示器响应
        checkOutItemIndicatorViewAction(sourceItemView: sourceItemView, destinationItemView: destinationItemView)
    }
    
    /// ItemView
    private func checkOutItemViewAction(sourceItemView: YYSegmentItemView, destinationItemView: YYSegmentItemView) {
        sourceItemView.percentChange(percent: 0)
        destinationItemView.percentChange(percent: 1)
        leftItemView = destinationItemView
        rightItemView = destinationItemView
        currentSelectedItemView = destinationItemView
    }
    
    /// associateScrollerView 响应
    private func checkOutItemContentViewAction(sourceItemView: YYSegmentItemView, destinationItemView: YYSegmentItemView) {
        let gap = abs(CGFloat(sourceItemView.index - destinationItemView.index))
        let offsetX = CGFloat(destinationItemView.index) * associateScrollerView!.bounds.width
        let offset = CGPoint.init(x: offsetX, y: 0)
        if gap == 1 && clickAnimation {
            associateScrollerView?.setContentOffset(offset, animated: true)
        }else{
            associateScrollerView?.setContentOffset(offset, animated: false)
        }
    }
    
    /// IndicatorView响应
    private func checkOutItemIndicatorViewAction(sourceItemView: YYSegmentItemView, destinationItemView: YYSegmentItemView) {
        var leftItemView = sourceItemView
        var rightItemView = destinationItemView
        if leftItemView.frame.origin.x > rightItemView.frame.origin.x {
            leftItemView = destinationItemView
            rightItemView = sourceItemView
        }
        let animationDuration = clickAnimation ? 0.25 : 0
        UIView.animate(withDuration: animationDuration) {
            rightItemView.layoutSubviews()
            leftItemView.layoutSubviews()
            self.indicatorView.reloadLayout(leftItemView: leftItemView, rightItemView: rightItemView)
        }
    }
}

// MARK: - 底部装 view 的 contentView 滚动处理
extension YYSegmentedView {
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard tabBarItems.count > 0 else {
            return
        }
        if keyPath == associateScrollerViewObserverKeyPath, let newContentOffset = change?[NSKeyValueChangeKey.newKey] as? CGPoint, let scrollView = associateScrollerView {
            /// 整体滑动进度
            totalPercent = (newContentOffset.x + scrollView.bounds.width) / scrollView.contentSize.width
            let userScroller = (scrollView.isTracking || scrollView.isDecelerating)
            if  scrollView.contentSize.width != 0 && scrollView.bounds.width != 0 && userScroller{
                contentOffsetChangeCalculation(scrollView: scrollView)
            }
        }
    }
    
    /// 滑动偏移计算
    private func contentOffsetChangeCalculation(scrollView:UIScrollView) {
        if let leftAndRightItemView = getLeftAndRightItemView() {
            contentOffsetChangeViewAction(leftItemView: leftAndRightItemView.leftItemView,
                                          rightItemView: leftAndRightItemView.rightItemView)
            delegate?.segMegmentCtlView?(segMegmentCtlView: self, dragToScroll: leftItemView, rightItemView: rightItemView)
        }
    }
    
    private func getLeftAndRightItemView() -> (leftItemView: YYSegmentItemView, rightItemView: YYSegmentItemView)? {
        guard tabBarItems.count > 0 else {
            return nil
        }
        
        guard let associateScrollerView = associateScrollerView, associateScrollerView.bounds.width > 0 else {
            return nil
        }
        let offsetX = associateScrollerView.contentOffset.x
        /// 边界,最右边和最左边的情况
        let basePercent = offsetX/associateScrollerView.contentSize.width
        let drageRange = basePercent...1
        if totalPercent < drageRange.lowerBound {
            leftItemView.percentChange(percent: 1)
            indicatorView.reloadLayout(leftItemView: leftItemView, rightItemView: leftItemView)
        }
        if totalPercent > drageRange.upperBound {
            indicatorView.reloadLayout(leftItemView: rightItemView, rightItemView: rightItemView)
            rightItemView.percentChange(percent: 1)
        }
        if !drageRange.contains(totalPercent){
            return nil
        }
        
        /// 计算 leftItemIndex， rightItemIndex
        let itemCount = tabBarItems.count
        let index = offsetX/associateScrollerView.bounds.width
        let leftItemIndex = max(0, min(itemCount - 1, Int((index))))
        let rightItemIndex = max(0, min(itemCount - 1, Int(ceil(index))))
        var rightPercent = CGFloat(index) - CGFloat(leftItemIndex)
        var leftPercent = 1 - rightPercent
        if leftItemIndex == rightItemIndex {
            leftPercent = 1
            rightPercent = 1
        }

        if let leftItemView = getItemView(atIndex: leftItemIndex),
            let rightItemView = getItemView(atIndex: rightItemIndex) {
            leftItemView.percentChange(percent: leftPercent)
            rightItemView.percentChange(percent: rightPercent)
            return (leftItemView,rightItemView)
        }
        return nil
    }
    
    private func contentOffsetChangeViewAction(leftItemView: YYSegmentItemView, rightItemView: YYSegmentItemView) {
        /// 边界情况:快速滑动的情况,contentOffset的变化是不连续的
        if (leftItemView,rightItemView) != (self.leftItemView,self.rightItemView) {
            
            /// 1、重制之前的itemView进度
            let curentItemViews = [leftItemView,rightItemView]
            if !curentItemViews.contains(self.leftItemView){
                self.leftItemView.percentChange(percent: 0)
            }
            if !curentItemViews.contains(self.rightItemView){
                self.rightItemView.percentChange(percent: 0)
            }
            
            /// 2、segMegmentScrollerView跟随用户的滑动
            var scrollerPageItemView = leftItemView
            if rightItemView.percent >= 0.5 {
                scrollerPageItemView = rightItemView
            }
            segmentScrollerViewSrollerToCenter(itemView: scrollerPageItemView, animated: true)
            
            /// 3、滚动选中
            if scrollerPageItemView != currentSelectedItemView{
                currentSelectedItemView = scrollerPageItemView
                delegate?.segMegmentCtlView?(segMegmentCtlView: self, dragToSelected: currentSelectedItemView)
            }
        }
        
        /// 4、变动指示器
        indicatorView.reloadLayout(leftItemView: leftItemView, rightItemView: rightItemView)
        self.leftItemView = leftItemView
        self.rightItemView = rightItemView
    }
    
    /// itemView 滚动到中间位置使完全显示出来
    private  func segmentScrollerViewSrollerToCenter(itemView: YYSegmentItemView, animated: Bool) {
        let scrollerView = segMegmentScrollerView
        let targetCenter = itemView.center
        let halfWidth = bounds.width/2
        
        let convertCenter = scrollerView.convert(targetCenter, to: self)
        var offsetX = scrollerView.contentOffset.x
        offsetX -= (halfWidth - convertCenter.x)
        offsetX = max(0, min(offsetX, scrollerView.contentSize.width - bounds.width))
        offsetX = offsetX - config.itemContentInset.left
        scrollerView.setContentOffset(CGPoint.init(x: offsetX, y: 0), animated: animated)
    }
}
