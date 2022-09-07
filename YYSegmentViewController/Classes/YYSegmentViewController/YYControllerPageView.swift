//
//  YYControllerPageView.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

open class YYControllerPageView: UIScrollView {

    /// 预加载范围，当前view前面几个，后面几个
    private var preLoadRange = 0...0
    /// item个数
    private var itemCount = 0
    /// 配置文件
    private var config: YYSegmentConfig!
    /// 初始化
    init(frame: CGRect, config: YYSegmentConfig) {
        super.init(frame: frame)
        self.config = config
        initSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initSubViews() {
        self.delegate = self
        self.backgroundColor = UIColor.clear
        self.isPagingEnabled = true
        self.bounces = false
        self.contentInset = UIEdgeInsets.zero
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.isDirectionalLockEnabled = true
        if #available(iOS 11.0, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
        self.preLoadRange = config.preLoadRange
    }
}

extension YYControllerPageView {
    
    /// 跳转到具体的位置
    /// - Parameter index: index
    internal func reloadCurrentIndex(index:NSInteger) {
        self.contentOffset = CGPoint.init(x: CGFloat(index) * self.bounds.width, y: 0)
    }
    
    /// 刷新数据
    internal func reloadData() {
        itemCount = config.containerControllerArr.count
        self.contentSize = CGSize.init(width: CGFloat(itemCount) * self.bounds.width, height: self.bounds.height)
        reloadCurrentShowView()
    }
    
    /// 根据 preLoadRange 添加视图
    private func reloadCurrentShowView() {
        guard itemCount > 0 else { return }
        let showPages = getShowPageIndex(maxCount: itemCount - 1)
        var pages = [NSInteger]()
        let left = showPages.leftIndex - preLoadRange.lowerBound
        let right = showPages.rightIndex + preLoadRange.upperBound
        for index in left...right {
            if (0...itemCount-1).contains(index){
                pages.append(index)
            }
        }
        for index in pages {
            let showView = (config.containerControllerArr[index].view)!
            showView.frame = CGRect.init(x: CGFloat(index) * bounds.width, y: 0, width: bounds.width, height: bounds.height)
            if !subviews.contains(showView){
                addSubview(showView)
            }
        }
    }
    
    private func getShowPageIndex(maxCount:NSInteger) -> (leftIndex: NSInteger, rightIndex: NSInteger) {
        let index = self.contentOffset.x / self.bounds.width
        guard !(index.isNaN || index.isInfinite) else {
            return (0, 0)
        }
        let leftItemIndex = max(0, min(maxCount, Int((index))))
        let rightItemIndex = max(0, min(maxCount, Int(ceil(index))))
        return (leftItemIndex,rightItemIndex)
    }
}

extension YYControllerPageView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if !gestureRecognizer.isKind(of: UIPanGestureRecognizer.classForCoder()) || !otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.classForCoder()) {
            return false
        }
        
        guard let gestureView = gestureRecognizer.view as? YYControllerPageView else {
            return false
        }
        
        guard let otherGestureView = otherGestureRecognizer.view as? YYControllerPageView else {
            return false
        }

        if gestureView != self {
            return false
        }
        
        let currentIndex = Int(gestureView.contentOffset.x / gestureView.bounds.width)
        let subIndex = Int(otherGestureView.contentOffset.x / otherGestureView.bounds.width)
        if subIndex > 0 {
            return false
        } else if subIndex == 0 {
            if currentIndex == gestureView.itemCount - 1 {
                return true
            }
            return false
        }
        return false
    }
}

extension YYControllerPageView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        reloadCurrentShowView()
    }
}
