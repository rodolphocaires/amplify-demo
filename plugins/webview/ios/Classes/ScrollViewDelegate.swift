//
//  ScrollViewDelegate.swift
//  Runner
//
//  Created by Victor Ferreira

import UIKit

class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}
