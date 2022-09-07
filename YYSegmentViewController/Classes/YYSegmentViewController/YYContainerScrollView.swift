//
//  YYContainerScrollView.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

@objc public protocol YYContainerScrollViewDagDelegate:NSObjectProtocol {
    func scrollView(scrollView:YYContainerScrollView, shouldScrollWithSubView subView:UIScrollView) -> Bool
}

open class YYContainerScrollView: UIScrollView {
    /// 配置文件
    public var config: YYSegmentConfig!
    /// 代理
    internal weak var dragDeleage: YYContainerScrollViewDagDelegate!
    ///
    private var observedViews = [UIScrollView]()
    /// 滑动监听
    private let observerKeyPath = "contentOffset"
    private let observerOptions: NSKeyValueObservingOptions = [.old,.new]
    private var observerContext = 0
    
    private var isObserving = true
    private var lock = false
    private var tapAtScrollerToTopLock = false
    
    
    /// scrollview已经到达顶部，再往下滑动的 Y 值
    public var scrollViewDragTopOffsetYBlock: ((UIScrollView, CGFloat) -> Void)?
    /// scrollview滑动到最小高度的进度
    public var scrollViewDragToMinimumHeightProgress: ((UIScrollView, CGFloat) -> Void)?
    
    public init(frame: CGRect, config: YYSegmentConfig) {
        super.init(frame: frame)
        self.config = config
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize() {
        self.showsVerticalScrollIndicator = config.showsVerticalScrollIndicator
        self.showsHorizontalScrollIndicator = config.showsHorizontalScrollIndicator
        /// 让ScrollView每次只能在一个方向滚动
        self.isDirectionalLockEnabled = true
        /// 回弹
        self.bounces = true
        self.delegate = self
        self.panGestureRecognizer.cancelsTouchesInView = false
        self.addObserver(self, forKeyPath: observerKeyPath, options: observerOptions, context: &observerContext)
    }
    
    /// 添加 headerView
    public func layoutParalaxHeader() {
        if let headView = config.headView  {
            self.contentInset = UIEdgeInsets.init(top: headView.bounds.height, left: 0, bottom: 0, right: 0)
            headView.center = CGPoint.init(x: bounds.width/2, y: -headView.bounds.height/2)
            insertSubview(headView, at: 0)
            self.contentOffset = CGPoint.init(x: 0, y: -self.contentInset.top)
        }  
        switch config.refreshType {
        case .container:
            self.bounces = true
        default:
            self.bounces = false
        }
    }

    deinit {
        self.removeObservedViews()
        self.removeObserver(self, forKeyPath: observerKeyPath, context: &observerContext)
    }
}

extension YYContainerScrollView {
    private func removeObservedViews() {
        for scrollView in observedViews {
            scrollView.removeObserver(self, forKeyPath: observerKeyPath, context: &observerContext)
        }
        observedViews.removeAll()
    }
    
    private func addObservedView(scrollView: UIScrollView) {
        if !self.observedViews.contains(scrollView) {
            self.observedViews.append(scrollView)
            lock = (scrollView.contentOffset.y > -scrollView.contentInset.top)
            scrollView.addObserver(self, forKeyPath: observerKeyPath, options: observerOptions, context: &observerContext)
        }
    }
}

extension YYContainerScrollView {
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView, config.headView != nil else {
            return
        }
        if keyPath == observerKeyPath,
        let newContentOffset = change?[NSKeyValueChangeKey.newKey] as? CGPoint,
        let oldContentOffset = change?[NSKeyValueChangeKey.oldKey] as? CGPoint {
            let diff = oldContentOffset.y - newContentOffset.y
            if diff == 0 || !isObserving { return }
            switch config.refreshType {
            case .list:
                if scrollView == self {
                    listRefreshSelfHandle(newContentOffset: newContentOffset, oldContentOffset: oldContentOffset)
                } else {
                    listRefreshOtherScrollViewHandle(scrollView: scrollView, newContentOffset: newContentOffset, oldContentOffset: oldContentOffset)
                }
            case .container:
                if scrollView == self {
                    containerRefreshSelfHandle(newContentOffset: newContentOffset, oldContentOffset: oldContentOffset)
                } else {
                    containerRefreshOtherScrollViewHandle(scrollView: scrollView, newContentOffset: newContentOffset, oldContentOffset: oldContentOffset)
                }
            }
        }
    }
    
    private func listRefreshOtherScrollViewHandle(scrollView:UIScrollView, newContentOffset:CGPoint, oldContentOffset:CGPoint) {
        lock = (scrollView.contentOffset.y > -scrollView.contentInset.top)
        //Manage scroll up
        let minimumHeight = -config.minimumHeight
        if self.contentOffset.y > -self.contentInset.top && self.contentOffset.y < minimumHeight {
            self.scrollView(scrollView: scrollView, contentOffset: CGPoint.zero)
        }
    }
    
    private func listRefreshSelfHandle(newContentOffset:CGPoint, oldContentOffset:CGPoint) {
        let diff = oldContentOffset.y - newContentOffset.y
        if diff > 0 && lock {
            self.scrollView(scrollView: self, contentOffset: oldContentOffset)
        } else if self.contentOffset.y < -self.contentInset.top {
            self.scrollView(scrollView: self, contentOffset: CGPoint.init(x: self.contentOffset.x, y: -self.contentInset.top))
        } else if self.contentOffset.y > (contentInset.bottom + contentSize.height - bounds.height) {
            self.scrollView(scrollView: self, contentOffset: CGPoint.init(x: self.contentOffset.x, y: (contentInset.bottom + contentSize.height - bounds.height)))
        }
        
        guard let _ = config.headView else { return }
        
        // 顶部下拉
        let contentInsetTop = self.contentInset.top
        let dragTopOffsetY = min(self.contentOffset.y + contentInsetTop,0)
        self.scrollViewDragTopOffsetYBlock?(self, abs(dragTopOffsetY))

        // 拉到最小距离的进度
        var minProgress:CGFloat = 0
        if self.contentInset.top != config.minimumHeight {
            minProgress = (self.contentOffset.y + config.minimumHeight) / (-self.contentInset.top + config.minimumHeight)
        }
        minProgress = 1 - min(minProgress, 1)
        self.scrollViewDragToMinimumHeightProgress?(self, minProgress)
    }
    
    private func containerRefreshOtherScrollViewHandle(scrollView:UIScrollView, newContentOffset:CGPoint, oldContentOffset:CGPoint) {
        //Adjust the observed scrollview's content offset
        lock = (scrollView.contentOffset.y > -scrollView.contentInset.top)
        
        let minimumHeight = -config.minimumHeight
        if self.contentOffset.y < minimumHeight {
            self.scrollView(scrollView: scrollView, contentOffset: CGPoint.zero)
        }
    }
    
    private func containerRefreshSelfHandle(newContentOffset:CGPoint, oldContentOffset:CGPoint) {
        let diff = oldContentOffset.y - newContentOffset.y
        let minimumHeight = -config.minimumHeight
        //Adjust self scroll offset when scroll down
        if diff > 0 && lock{
            self.scrollView(scrollView: self, contentOffset: oldContentOffset)
        } else if self.contentOffset.y < -self.contentInset.top && !self.bounces {
            self.scrollView(scrollView: self, contentOffset: CGPoint.init(x: self.contentOffset.x, y: -self.contentInset.top))
        } else if self.contentOffset.y > minimumHeight {
            self.scrollView(scrollView: self, contentOffset: CGPoint.init(x: self.contentOffset.x, y: minimumHeight))
        }
        
        guard let _ = config.headView else { return }
        
        // 顶部下拉
        let contentInsetTop = self.contentInset.top
        let dragTopOffsetY = min(self.contentOffset.y + contentInsetTop,0)
        self.scrollViewDragTopOffsetYBlock?(self, abs(dragTopOffsetY))

        // 拉到最小距离的进度
        var minProgress:CGFloat = 0
        if self.contentInset.top != config.minimumHeight {
            minProgress = (self.contentOffset.y + config.minimumHeight) / (-self.contentInset.top + config.minimumHeight)
        }
        minProgress = 1 - min(minProgress, 1)
        self.scrollViewDragToMinimumHeightProgress?(self, minProgress)
    }
    
    private func scrollView(scrollView:UIScrollView, contentOffset:CGPoint) {
        if tapAtScrollerToTopLock == true && scrollView == self {
            return
        }
        isObserving = false
        scrollView.contentOffset = contentOffset
        isObserving = true
    }
}


extension YYContainerScrollView : UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lock = false
        self.removeObservedViews()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && config.refreshType == .list {
            lock = false
            self.removeObservedViews()
        }
    }
    
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        tapAtScrollerToTopLock = true
        return (contentOffset.y > -(contentInset.top + config.minimumHeight) && contentOffset.y < -config.minimumHeight)
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        tapAtScrollerToTopLock = false
    }
    
}

extension YYContainerScrollView : UIGestureRecognizerDelegate {
    /// 两个scrollView同时滚动
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }
        
        // Consider scroll view pan only
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
            return false
        }
        guard let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        /// 横行滚动禁止联动
        let velocity = otherGestureRecognizer.velocity(in: self)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        
        // Tricky case: UITableViewWrapperView
        if scrollView.superview?.isKind(of: UITableView.classForCoder()) == true {
            return false
        }
        
        var shouldScroll = true
        if dragDeleage?.scrollView(scrollView: self, shouldScrollWithSubView: scrollView) == true {
            shouldScroll = true
            self.addObservedView(scrollView: scrollView)
        } else {
            shouldScroll = false
        }
        return shouldScroll
    }
}
