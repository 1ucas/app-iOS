//
//  AppDelegate.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 18/08/17.
//  Copyright © 2017 MacMagazine. All rights reserved.
//

import CoreSpotlight
import StoreKit
import UIKit

extension Notification.Name {
	static let shortcutActionLastPost = Notification.Name("shortcutActionLastPost")
	static let shortcutActionRecentPost = Notification.Name("shortcutActionRecentPost")
	static let reloadWeb = Notification.Name("reloadWeb")
	static let scrollToTop = Notification.Name("scrollToTop")
	static let favoriteUpdated = Notification.Name("favoriteUpdated")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	// MARK: - Properties -

	var window: UIWindow?
	var previousController: UIViewController?

	// MARK: - Window lifecycle -

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		// Override point for customization after application launch.
        applyTheme()

		guard let tabBarViewController = window?.rootViewController as? UITabBarController else {
			return true
		}
		tabBarViewController.delegate = self

		guard let splitViewController = tabBarViewController.viewControllers?.first as? UISplitViewController else {
			return true
		}
		splitViewController.delegate = self
		splitViewController.preferredDisplayMode = .allVisible
		splitViewController.preferredPrimaryColumnWidthFraction = 0.33

		// Apple Watch Session
		WatchSessionManager.shared.startSession()

		// AppStore Review
		if Settings().shouldAskForReview() {
			SKStoreReviewController.requestReview()
		}

		// Push Notification
		PushNotification().setup(options: launchOptions)

		return true
	}

}

// MARK: - Theme -

extension AppDelegate {
	fileprivate func applyTheme() {
		guard let isDarkMode = UserDefaults.standard.object(forKey: "darkMode") as? Bool else {
			let theme: Theme = LightTheme()
			theme.apply(for: UIApplication.shared)

			return
		}
		let theme: Theme = isDarkMode ? DarkTheme() : LightTheme()
		theme.apply(for: UIApplication.shared)
	}
}

// MARK: - Splitview Delegate -

extension AppDelegate: UISplitViewControllerDelegate {
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		guard let secondaryAsNavController = secondaryViewController as? UINavigationController,
			let topAsDetailController = secondaryAsNavController.topViewController as? PostsDetailViewController
			else {
				return false
		}
		return topAsDetailController.links.isEmpty
	}
}

// MARK: - TabController Delegate -

extension AppDelegate: UITabBarControllerDelegate {
	// Tap 2x to Top
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if let navVC = viewController as? UINavigationController,
			let vc = navVC.children[0] as? UITableViewController {
			if previousController == vc {
				vc.tableView.setContentOffset(.zero, animated: true)
			}
			previousController = vc
		} else if let navVC = viewController as? UINavigationController,
			let vc = navVC.children[0] as? PodcastViewController {
			if previousController == vc {
				NotificationCenter.default.post(name: .scrollToTop, object: nil)
			}
			previousController = vc
		} else if let splitVC = viewController as? UISplitViewController,
			let navVC = splitVC.children[0] as? UINavigationController,
			let vc = navVC.children[0] as? PostsMasterViewController {
			if previousController == vc || previousController == nil {
				if navVC.children.count > 1,
					let navDetail = navVC.children[1] as? UINavigationController,
					let detail = navDetail.children[0] as? PostsDetailViewController,
					navVC.visibleViewController == detail {
					navVC.popViewController(animated: true)
				} else {
					vc.tableView.setContentOffset(.zero, animated: true)
				}
			}
			previousController = vc
		}
	}
}

// MARK: - Shortcut -

extension AppDelegate {
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		if shortcutItem.type == "openLastSeenPost" ||
			shortcutItem.type == "openMostRecentPost" {
			guard let tabController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else {
				return
			}
			tabController.selectedIndex = 0

			NotificationCenter.default.post(name: shortcutItem.type == "openLastSeenPost" ? .shortcutActionLastPost : .shortcutActionRecentPost, object: nil)
		}
	}
}

// MARK: - Spotlight search -

extension AppDelegate {
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		if userActivity.activityType == CSSearchableItemActionType {
			if let identifier = userActivity.userInfo? [CSSearchableItemActivityIdentifier] as? String {
				showDetailController(with: identifier)
				return true
			}
		}
		return false
	}
}
