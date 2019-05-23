//
//  PushNotification.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 21/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import Kingfisher
import OneSignal
import UIKit

class PushNotification {
	func setup(options: [UIApplication.LaunchOptionsKey: Any]?) {
		let notificationReceived: OSHandleNotificationReceivedBlock = { result in
			self.updateDatabase(for: nil)
		}

		let notificationAction: OSHandleNotificationActionBlock = { result in
			// This block gets called when the user reacts to a notification received
			guard let payload = result?.notification.payload,
				let additionalData = payload.additionalData,
				let url = additionalData as? [String: String]
				else {
					return
			}
			self.updateDatabase(for: url["url"])
		}

		let key: [UInt8] = [114, 66, 66, 33, 7, 95, 7, 81, 76, 21, 6, 42, 97, 98, 86, 91, 80, 6, 89, 35, 20, 18, 116, 72, 14, 87, 1, 81, 18, 85, 123, 55, 120, 4, 89, 81]

		OneSignal.initWithLaunchOptions(options, appId: Obfuscator().reveal(key: key), handleNotificationReceived: notificationReceived, handleNotificationAction: notificationAction, settings: [kOSSettingsKeyAutoPrompt: false])
		OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
		OneSignal.promptForPushNotifications(userResponse: { _ in })
	}
}

extension PushNotification {
	func updateDatabase(for url: String?) {

		logD(url)

		var images: [String] = []
		API().getPosts(page: 0) { post in

			DispatchQueue.main.async {
				guard let post = post else {
					// Prefetch images to be able to sent to Apple Watch
					let urls = images.compactMap { URL(string: $0) }
					let prefetcher = ImagePrefetcher(urls: urls)
					prefetcher.start()

					return
				}
				images.append(post.artworkURL)
				CoreDataStack.shared.save(post: post)

				if let url = url, post.link == url {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						showDetailController(with: url)
					}
				}
			}
		}
	}
}
