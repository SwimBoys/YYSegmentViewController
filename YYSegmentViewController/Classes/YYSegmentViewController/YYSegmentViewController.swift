//
//  YYSegmentViewController.swift
//  YYSegmentViewController
//
//  Created by youyongpeng on 2022/7/21.
//

import UIKit

open class YYSegmentViewController: UIViewController {
    
    /// 配置文件
    public var config: YYSegmentConfig!
    /// 最底部的ScrollView
    public var containerScrView: YYContainerScrollView!
    /// 下边装view的容器
    public var pageView: YYControllerPageView!
    /// 上边装item的容器
    public var segmentCtlView: YYSegmentedView!
    /// scrollview到顶部往下滑动的 Y 值
    public var scrollViewDragTopOffsetYBlock: ((UIScrollView, CGFloat) -> Void)?
    /// scrollview滑动到最小高度的进度
    public var scrollViewDragToMinimumHeightProgress: ((UIScrollView, CGFloat) -> Void)?
    /// 判断是否设置frame
    private var isSetFrame = false
    /// 初始化完成，可以再次方法里获取一些view的frame
    public var initDone: (() -> Void)?
    
    /// 初始化
    public convenience init(_ config: YYSegmentConfig) {
        self.init()
        self.config = config
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 添加子控件，为了防止viewDidLoad获取到的view的bounds不对
        if !isSetFrame {
            isSetFrame = true
            relayoutSubViews()
            reloadViewControllers()
            closeAutomaticallyAdjusts()
            initDone?()
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initSubviews()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        if let screenEdgePanGestureRecognizer = getScreenEdgePanGestureRecognizer() {
            containerScrView.panGestureRecognizer.require(toFail: screenEdgePanGestureRecognizer)
            pageView.panGestureRecognizer.require(toFail: screenEdgePanGestureRecognizer)
        }
    }
    
    private func initSubviews() {
        containerScrView = YYContainerScrollView(frame: view.bounds, config: config)
        containerScrView.dragDeleage = self
        containerScrView.backgroundColor = .clear
        containerScrView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        view.addSubview(containerScrView)
        containerScrView.scrollViewDragTopOffsetYBlock = { [weak self] (scrollView, offsetY) in
            guard let this = self else {return}
            this.scrollViewDragTopOffsetYBlock?(scrollView, offsetY)
        }
        containerScrView.scrollViewDragToMinimumHeightProgress = { [weak self] (scrollView, progress) in
            guard let this = self else {return}
            this.scrollViewDragToMinimumHeightProgress?(scrollView, progress)
        }
        
        pageView = YYControllerPageView(frame: CGRect.zero, config: config)
        containerScrView.addSubview(pageView)

        segmentCtlView = YYSegmentedView(frame: CGRect.zero, tabBarItems: [UITabBarItem](), config: config)
        containerScrView.addSubview(segmentCtlView)
        segmentCtlView.associateScrollerView = pageView
    }
    
    private func relayoutSubViews() {
        let screenW = view.bounds.width
        let screenH = view.bounds.height
        var segmentControlSize: CGSize = CGSize.zero
        var containerFrameY: CGFloat = 0
        var segmentCtlViewY: CGFloat = 0
        var containerHeight: CGFloat = 0

        switch config.segmentControlPositionType {
        case .nav(let size, let navigatioBarHeight):
            containerHeight = screenH - config.minimumHeight - navigatioBarHeight
            containerFrameY = navigatioBarHeight
            segmentControlSize = size
            segmentCtlViewY = 0
            if config.isInherit {
                self.navigationItem.titleView = segmentCtlView
            } else {
                self.parent?.navigationItem.titleView = segmentCtlView
            }
        case .top:
            let height = config.segmentControlHeight
            containerHeight = screenH - (config.minimumHeight + height)
            containerFrameY = height
            segmentControlSize = CGSize(width: config.segmentControlWidth, height: config.segmentControlHeight)
            
        case .bottom:
            containerHeight = screenH - (config.minimumHeight + config.segmentControlHeight)
            containerFrameY = 0
            segmentControlSize = CGSize(width: config.segmentControlWidth, height: config.segmentControlHeight)
            segmentCtlViewY = containerHeight
            
        case .customFrame(let containerScrFrame, let segmentCtlFrame, let containerFrame):
            containerScrView.frame = containerScrFrame
            segmentCtlView.frame = segmentCtlFrame
            pageView.frame = containerFrame
            containerScrView.contentSize = CGSize.init(width: screenW, height: segmentCtlFrame.height + containerFrame.height)
            containerScrView.layoutParalaxHeader()
            return
        }

        let segmentCtlFrame = CGRect.init(origin: CGPoint.init(x: 0, y: segmentCtlViewY), size: segmentControlSize)
        segmentCtlView.frame = segmentCtlFrame
        
        let containerFrame = CGRect.init(x: 0, y: containerFrameY, width: screenW, height: containerHeight)
        pageView.frame = containerFrame
        
        containerScrView.contentSize = CGSize.init(width: screenW, height: screenH - config.minimumHeight)
        containerScrView.layoutParalaxHeader()
    }
    
    private func reloadViewControllers() {
        config.containerControllerArr.forEach { (vc) in
            vc.removeFromParent()
        }
        for ctl in config.containerControllerArr {
            addChild(ctl)
        }
        pageView.reloadCurrentIndex(index: 0)
        pageView.reloadData()
        segmentCtlView.tabBarItems = config.containerControllerArr.map({  $0.tabBarItem })
        segmentCtlView.reloadData()
    }
    
    /// 关闭自动调整
    private func closeAutomaticallyAdjusts() {
        if #available(iOS 11.0, *) {
            self.containerScrView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    /// 对于一些特殊的需要自己指定位置信息
    open func relayoutSegmentControlAndPageViewFrame(segmentControlFrame:CGRect, pageViewFrame:CGRect) {
        segmentCtlView.frame = segmentControlFrame
        pageView.frame = pageViewFrame
    }
    
    /// 动态添加view
    /// - Parameters:
    ///   - ctl: 控制器
    ///   - index: index
    ///   - title: 标题
    public func insertOneViewController(ctl: UIViewController, index: NSInteger, title: String) {
        if !self.children.contains(ctl) {
            addChild(ctl)
            let itemIndex = max(0, min(index, config.containerControllerArr.count))
            config.containerControllerArr.insert(ctl, at: itemIndex)
            
            pageView.reloadCurrentIndex(index: itemIndex)
            pageView.reloadData()
            
            segmentCtlView.tabBarItems.insert(ctl.tabBarItem, at: index)
            config.itemDefaultSelectedIndex = itemIndex
            segmentCtlView.reloadData()
        }
    }
    
    /// 跳转到 index 视图
    /// - Parameters:
    ///   - Index: Index
    ///   - animation: animation
    public func selected(at Index:NSInteger, animation: Bool)  {
        guard (config.containerControllerArr.count > Index && Index >= 0) else {
            return
        }
        segmentCtlView.selected(at: Index, animation: animation)
    }
    
    private func getScreenEdgePanGestureRecognizer() -> UIScreenEdgePanGestureRecognizer? {
        if let gestureRecognizers = self.parent?.navigationController?.view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if let recognizer = recognizer as? UIScreenEdgePanGestureRecognizer {
                    return recognizer
                }
            }
        }
        return nil;
    }
}

extension YYSegmentViewController: YYContainerScrollViewDagDelegate {
    open func scrollView(scrollView: YYContainerScrollView, shouldScrollWithSubView subView: UIScrollView) -> Bool {
        if subView == pageView {
            return false
        }
        return true
    }
}
