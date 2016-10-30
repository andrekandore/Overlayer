//
//  OverlayableViewController.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/02.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit

open class OverlayableViewController : UIViewController, OverlayableViewControllerProtocol {
    
    @IBOutlet open var draggableOverlayCoordinators : [DraggableSegueCoordinator] = []
    @IBOutlet open var viewForDraggedDismissalOutlet : UIView? = nil
    @IBInspectable open var lightStatusBar : Bool = true
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.attempt(overlaying: segue, sender: sender)
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get { return self.statusBarStyle } set {}
    }
}


open class OverlayableNavigationController : UINavigationController, OverlayableViewControllerProtocol {
    
    @IBOutlet open var draggableOverlayCoordinators : [DraggableSegueCoordinator] = []
    @IBOutlet open var viewForDraggedDismissalOutlet : UIView? = nil
    @IBInspectable open var lightStatusBar : Bool = true
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.attempt(overlaying: segue, sender: sender)
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get { return self.statusBarStyle } set {}
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.viewForDraggedDismissalOutlet = self.navigationBar
    }
}

open class OverlayableTabBarController : UITabBarController, OverlayableViewControllerProtocol {
    
    @IBOutlet open var draggableOverlayCoordinators : [DraggableSegueCoordinator] = []
    @IBOutlet open var viewForDraggedDismissalOutlet : UIView? = nil
    @IBInspectable open var lightStatusBar : Bool = true
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.attempt(overlaying: segue, sender: sender)
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get { return self.statusBarStyle } set {}
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.viewForDraggedDismissalOutlet = self.navigationController?.navigationBar
    }
}
