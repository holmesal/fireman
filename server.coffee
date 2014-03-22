require 'newrelic'
Firebase = require 'firebase'
apn = require 'apn'
winston = require 'winston'
http = require 'http'

# Store clients in a firebase
Client = require './client'


# Firebase creds
# TODO - add private firebase creds when that makes sense
rootRef = new Firebase 'http://fireman.firebaseio.com'
users = rootRef.child 'users'


clientOptions = 
	pushQueueURL: 'http://orbit.firebaseio.com/pushQueue'
	# TODO - host these files on S3 and read them in here
	# certData: 'some-cert-data'
	# keyData: 'some-key-data'

# Create a new client
# client = new Client clientOptions

# Set up and bind all of the existing clients
users.on 'child_added', (snapshot) ->
	console.log "New client!"
	client = new Client snapshot.ref()



# Create a new connection with the apn servers
# apnConnection = new apn.Connection apnOptions

# Parser for push queue items
parseItem = (item) ->
	winston.info 'parsing item'
	winston.info item
	# TODO - figure out how properly store a timestamp and use it here to only send new-ish notifications
	# For now, assume it's a valid notification to send
	# for receiver in item.receivers
	# 	winston.ind
	# receiverID = '61483:23458'
	sendPushTo receiverID, item

# Send a push notification to the mentioned receiver
sendPushTo = (userID, data) ->
	# Get the owner's device token
	# user = rootRef.child('users').child(userID).child('pushToken')
	user.once 'value', (snapshot) ->
		token = snapshot.val()

		# Construct a device with this token
		device = new apn.Device data.deviceToken

		# Construct a notification with this device
		note = new apn.Notification
		# Set notification params
		note.expiry = Math.floor(Date.now() / 1000) + 3600 # 1 hour
		note.badge = 3
		note.sound = 'ping.aiff'
		note.alert = '"Aww yeah. Dat push notif..."'
		note.payload = # for the app
			messageFrom: 'Bob Barker'
			# 'content-available': 1

		@log "pushing notification to token #{token}"

		# Push out on the apn connection
		apnConnection.pushNotification note, device

# Remove a snapshot
removeSnapshot = (snapshot) ->
	snapshot.ref().remove()

# Set a listener for new items - this will also fire for every item in the queue when the server starts
# pushQueue.on 'child_added', (snapshot) ->
# 	parseItem snapshot.val()


# Create a little http server to respond to uptime requests
server = http.createServer (req, res) ->
	res.writeHead 200, 
		'Content-Type': 'text/plain'
	res.end 'The earshot server is up!'
server.listen process.env.PORT