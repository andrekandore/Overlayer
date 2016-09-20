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


