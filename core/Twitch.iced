request = require 'request'
twitchy = require 'twitchy'

class exports.Twitch
	constructor: (@Mikuia) ->

	init: ->
		if @Mikuia.settings.twitch.key != 'TWITCH_API_KEY' && @Mikuia.settings.twitch.secret != 'TWITCH_API_SECRET'
			@twitch = new twitchy {
				key: @Mikuia.settings.twitch.key
				secret: @Mikuia.settings.twitch.secret
			}
		else
			@Mikuia.Log.fatal 'Please specify correct Twitch API key and secret.'

	findChannel: (input, callback) ->
		Channel = new Mikuia.Models.Channel input

		await Channel.exists defer err, exists
		if err or not exists
			await Mikuia.Database.hget 'mikuia:ids', input, defer err2, username
			if not err2 and username?
				Channel = new Mikuia.Models.Channel username
				await Channel.exists defer err, exists
				if not err and exists
					callback Channel
				else
					callback null
			else
				callback null
		else
			callback Channel

	getChatters: (channel, callback) ->
		channel = channel.replace('#', '')
		request 'http://tmi.twitch.tv/group/user/' + channel + '/chatters', (error, response, body) ->
			if !error && response.statusCode == 200
				data = {}
				try
					data = JSON.parse body
				catch e
					console.log e
				callback false, data
			else
				callback true, null

	getStreams: (channels, callback) ->
		completed = false
		setTimeout () =>
			if !completed
				callback true, 'Timed out.'
		, 10000
		@twitch._get 'streams/?channel=' + channels.join(',') + '&client_id=' + @Mikuia.settings.twitch.key, (err, result) =>
			if err || not result.req.res.body?.streams?
				if !completed
					@Mikuia.Log.error 'Failed to obtain stream list from Twitch API.'
					callback true, null
					completed = true
			else
				if !completed
					callback err, result.req.res.body.streams
					completed = true
