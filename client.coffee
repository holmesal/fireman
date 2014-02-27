{EventEmitter} = require 'events'
winston = require 'winston'
Firebase = require 'firebase'
apn = require 'apn'
fs = require 'fs'
# Export a class for a client


class Client extends EventEmitter

	log: (thing) ->
		console.log thing

	constructor: (@options) ->

		# TODO - check options and emit an error if missing things

		# Event listeners

		# Create the APN connection
		@initAPN()

		@initFirebase()

	initAPN: ->
		# APN options
		apnOptions = 
			gateway: 'gateway.sandbox.push.apple.com'
			key: @options.key
			cert: @options.cert

		# Create the connection
		@connection = new apn.connection apnOptions

	initFirebase: =>
		# Connect to their firebase
		@rootRef = new Firebase @options.pushQueueURL

		# Listen for childAdded events
		@rootRef.on 'child_added', (snapshot) =>
			@parseItem snapshot.val(), snapshot.ref()
		

	parseItem: (item, ref) =>
		@log 'got item to parse!'
		@log item

		# TODO - check to make sure all of the required fields are there - especially deviceToken

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
		note.sound = if item.sound then item.sound else 'ping.aiff'
		note.alert = if item.alert then item.alert else 'Hello from Fireman!'
		if item.payload
			note.payload = item.payload
		else
			note.payload = 
				fireman: 'such push. very notify.'

		console.log note

		# Do the damn thing
		setTimeout =>
			@connection.pushNotification note, device
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

