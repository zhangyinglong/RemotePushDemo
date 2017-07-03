var apn = require('apn');

if (process.argv.length == 3) {
	// Enter the device token from the Xcode console
	// var deviceToken = '8c6f8b7056613a5223c690fb171697c524173b9c39e7dff688c66f0b23fbefdb';
	var deviceToken = process.argv[2];

	// Set up apn with the APNs Auth Key
	var apnProvider = new apn.Provider({  
	     token: {
	        key: 'XXXXXX.p8', // Path to the key p8 file
	        keyId: 'XXXXXX', // The Key ID of the p8 file (available at https://developer.apple.com/account/ios/certificate/key)
	        teamId: 'XXXXXX', // The Team ID of your Apple Developer Account (available at https://developer.apple.com/account/#/membership/)
	    },
	    production: false // Set to true if sending a notification to a production iOS app
	});

	// Prepare a new notification
	var notification = new apn.Notification();

	// Specify your iOS app's Bundle ID (accessible within the project editor)
	notification.topic = 'com.domain.example';

	// Set expiration to 1 hour from now (in case device is offline)
	notification.expiry = Math.floor(Date.now() / 1000) + 3600;

	// Set app badge indicator
	notification.badge = 1;

	// Play ping.aiff sound when the notification is received
	notification.sound = 'default';

	// Display the following message (the actual notification text, supports emoji)
	notification.alert = 'Hello World \u270C';

	// Send any extra payload data with the notification which will be accessible to your app in didReceiveRemoteNotification
	notification.payload = {id: 123};

	// Actually send the notification
	apnProvider.send(notification, deviceToken).then(function(result) {  
	    // Check the result for any failed devices
	    console.log(result);
	});
} else {
	console.log("Usage: node push.js <deviceToken>");
}
