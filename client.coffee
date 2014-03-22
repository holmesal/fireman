{EventEmitter} = require 'events'
winston = require 'winston'
Firebase = require 'firebase'
apn = require 'apn'
# fs = require 'fs'
# Export a class for a client


class Client extends EventEmitter

	log: (thing) ->
		winston.info thing
		newLogRef = @logs.push()
		newLogRef.set thing

	constructor: (@ref) ->

		@creds = {}

		# Ref for logging
		@logs = @ref.child 'logs'

		# Specific listeners for key/cert - want to cycle the connection if these change
		keyRef = @ref.child 'key'
		keyRef.on 'value', (snapshot) =>
			@creds.key = snapshot.val()
			@tryAPN()

		certRef = @ref.child 'cert'
		certRef.on 'value', (snapshot) =>
			@creds.cert = snapshot.val()
			@tryAPN()

		urlRef = @ref.child 'firebaseURL'
		urlRef.on 'value', @initFirebase

		# Listener for everything else
		@ref.on 'value', (snapshot) =>
			@data = snapshot.val()

		# TODO - check options and emit an error if missing things

		# Event listeners

		# Create the APN connection
		# @initAPN()

		# @initFirebase()

	tryAPN: ->
		if @creds.key and @creds.cert
			@initAPN()
		else
			winston.info 'not enough stuff yet'

	initAPN: ->
		winston.info 'connecting to APN server'
		# APN options
		apnOptions = 
			gateway: 'gateway.sandbox.push.apple.com'
			keyData: @creds.key
			certData: @creds.cert

		# if @connection

		# Create the connection
		@connection = new apn.Connection apnOptions

		@connection.on 'error', (err, two, three) =>
			@emit 'err', err
			console.log 'omg error'
			console.log err
		@connection.on 'transmissionError', (err) =>
			@emit 'err', err
			console.log err
		@connection.on 'connected', ->
			console.log 'aww yeah connected!'

	initFirebase: (snapshot) =>
		# This actually gets fired every time a keystroke happens.
		# Should tweak the angular app to handle this a little better.
		url = snapshot.val()
		if url.indexOf('firebaseio.com') > -1
			# Connect to their firebase
			@rootRef = new Firebase url
			
			# Observe connect/disconnect events
			@rootRef.child('.info/connected').on 'value', (connectedSnap) =>
				state = connectedSnap.val()
				if state is true
					@log "Connected to #{url}/pushQueue"
				else
					@log "Not connected to #{url}/pushQueue"
			# try
			# 	@pushQueue = new Firebase "#{url}/pushQueue"
			# 	console.log 'connected!'

			# Listen for childAdded events on the push queue
			@pushQueue = @rootRef.child 'pushQueue'
			@pushQueue.on 'child_added', (snapshot) =>
				try
					@parseItem snapshot.val(), snapshot.ref()
				catch err
					console.error "Error parsing item... deleting..."
					console.error snapshot.val()
					console.error err
					@deleteNotification snapshot.ref()
			# catch err
			# 	@emit 'err', err
			# 	console.log err
			
		

	parseItem: (item, ref) =>

		# TODO - check to make sure all of the required fields are there - especially deviceToken
		if item.deviceToken

			# Create a new device
			device = new apn.Device item.deviceToken

			# Create a new notification
			note = new apn.Notification

			# Use provided options, or defaults
			if item.expiry
				note.expiry = item.expiry
			else
				note.expiry = Math.floor(Date.now() / 1000) + 3600
			
			note.badge = if item.badge then item.badge else 1
			note.sound = if item.sound then item.sound else 'default'
			note.alert = if item.alert then item.alert else 'Hello from Fireman!'
			if item.payload
				note.payload = item.payload
			else
				note.payload = 
					fireman: 'such push. very notify.'

			console.log note

			# Do the damn thing
			# TODO - remove this timeout!
			@log "Sending push notification to device `#{item.deviceToken}`"
			setTimeout =>
				@connection.pushNotification note, device
				@deleteNotification ref
				# Increment this user's pushes
				unless @data.count
					@data.count = 0
				@ref.child('count').set @data.count + 1
			, 2000

		else
			@log "Got a push notification without a device token - deleting."
			setTimeout =>
				@deleteNotification ref
			, 2000

	deleteNotification: (ref) ->
		ref.remove()

		# Default notification options
		# defaults = 
		# 	expiry: Math.floor(Date.now() / 1000) + 3600
		# 	badge: 1
		# 	sound: 'ping.aiff'
		# 	alert: 'Hello from Fireman!'
		# 	payload:
		# 		fireman: 'such wow'

		# Extend with any options they set
		# options = defaults.extend @options


module.exports = Client

