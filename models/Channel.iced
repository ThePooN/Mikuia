fs = require 'fs'
gm = require 'gm'
request = require 'request'

class exports.Channel extends Mikuia.Model
	constructor: (name) ->
		@model = 'channel'
		@name = name.replace('#', '').toLowerCase()

	# Core functions, changing those often end up breaking half of the universe.

	exists: (callback) ->
		@_exists '', callback

	getName: -> @name

	isAdmin: ->
		@name in Mikuia.settings.bot.admins

	isBanned: (callback) ->
		Mikuia.Database.sismember 'mikuia:banned', @getName(), callback

	isBot: (callback) ->
		Mikuia.Database.sismember 'mikuia:bots', @getName(), callback

	isLevelDisabled: (callback) ->
		Mikuia.Database.sismember 'mikuia:levels:disabled', @getName(), callback

	isLive: (callback) ->
		Mikuia.Database.sismember 'mikuia:streams', @getName(), callback

	isPrioritized: (callback) ->
		Mikuia.Database.sismember 'mikuia:prioritized', @getName(), callback

	isStreamer: (callback) ->
		@_exists 'plugins', callback

	# Info & settings

	getAll: (callback) ->
		@_hgetall '', callback

	getInfo: (field, callback) ->
		@_hget '', field, callback

	getSetting: (plugin, field, callback) ->
		await @_hget 'plugin:' + plugin + ':settings', field, defer err, data
		if Mikuia.Plugin.getManifest(plugin)?.settings?.channel?[field]?
			setting = Mikuia.Plugin.getManifest(plugin).settings.channel[field]
			if !data? && setting.default?
				data = setting.default
			if setting.type == 'boolean'
				if data == 'true'
					data = true
				if data == 'false'
					data = false
		callback err, data

	getSettings: (plugin, callback) ->
		@_hgetall 'plugin:' + plugin + ':settings', callback

	setInfo: (field, value, callback = ->) ->
		@_hset '', field, value, callback

	setSetting: (plugin, field, value, callback) ->
		if value != ''
			@_hset 'plugin:' + plugin + ':settings', field, value, callback
		else
			@_hdel 'plugin:' + plugin + ':settings', field, callback

	# Enabling & disabling, whatever.

	disable: (callback) ->
		Mikuia.Database.srem 'mikuia:channels', @getName(), callback

	enable: (callback) ->
		Mikuia.Database.sadd 'mikuia:channels', @getName(), callback

	isEnabled: (callback) ->
		Mikuia.Database.sismember 'mikuia:channels', @getName(), callback

	# Commands
	queryCommand: (trigger, user, callback) ->
		await
			@getCommand trigger, defer commandError, command
			@getCommandSettings trigger, true, defer settingsError, settings

		await @isCommandAllowed settings, user, defer isAllowed, reasons

		callback commandError || settingsError, {command, settings, isAllowed, reasons}

	isCommandAllowed: (settings, user, callback) ->
		if user?
			chatter = new exports.Channel user.username
			
		isAllowed = true
		reasons = []

		if !user? && ((settings?._minLevel && parseInt(settings._minLevel) > 0) || settings?._onlyMods || settings?._onlySubs || settings?._onlyBroadcaster || (settings?._coinCost && parseInt(settings._coinCost) > 0))
			isAllowed = false
			reasons.push 'anonymous'

		if user? and settings?._minLevel and parseInt(settings._minLevel) > 0
			await chatter.getLevel @getName(), defer whateverError, userLevel
			if userLevel < parseInt(settings._minLevel)
				isAllowed = false
				reasons.push 'level'

		if user? and settings?._onlyMods and not chatter.isModOf @getName()
			isAllowed = false
			reasons.push 'mod'

		if user? and settings?._onlySubs and not user.subscriber
			isAllowed = false
			reasons.push 'subscriber'

		if user? and settings?._onlyBroadcaster and user.username isnt @getName()
			isAllowed = false
			reasons.push 'broadcaster'

		if user? and settings?._coinCost and parseInt(settings._coinCost) > 0
			await Mikuia.Database.zscore 'channel:' + @getName() + ':coins', user.username, defer error, balance
			if !balance? or parseInt(balance) < parseInt(settings._coinCost)
				isAllowed = false
				reasons.push 'coins'

		if user? and user.username == @getName()
			isAllowed = true
			reasons = []

		callback isAllowed, reasons

	addCommand: (command, handler, callback) ->
		@_hset 'commands', command, handler, callback

	getCommand: (command, callback) ->
		@_hget 'commands', command, callback

	getCommandSettings: (command, defaults, callback) ->
		await
			@_hgetall 'command:' + command, defer err, settings
			@getCommand command, defer commandError, handler

		settings = {} unless settings? # see iced bug #50

		if !commandError
			for settingName, setting of settings
				if settings[settingName] == 'true'
					settings[settingName] = true
				if settings[settingName] == 'false'
					settings[settingName] = false

			if Mikuia.Plugin.getHandler(handler)?.settings?
				for settingName, setting of Mikuia.Plugin.getHandler(handler).settings
					if defaults && !settings[settingName]?
						settings[settingName] = setting.default

		callback err, settings

	getCommands: (callback) ->
		@_hgetall 'commands', callback

	removeCommand: (command, callback) ->
		@_hdel 'commands', command, callback

	setCommandSetting: (command, key, value, callback) ->
		if value != ''
			await @_hset 'command:' + command, key, value, callback
		else
			await @_hdel 'command:' + command, key, callback

	# Plugins

	disablePlugin: (name, callback) ->
		@_srem 'plugins', name, callback

	enablePlugin: (name, callback) ->
		@_sadd 'plugins', name, callback

	getEnabledPlugins: (callback) ->
		@_smembers 'plugins', callback

	isPluginEnabled: (name, callback) ->
		@_sismember 'plugins', name, callback

	getPluginData: (plugin, key, callback) ->
		if !callback?
			@_hgetall 'plugin:' + plugin + ':data', key
		else
			@_hget 'plugin:' + plugin + ':data', key, callback

	setPluginData: (plugin, key, value, callback) ->
		@_hset 'plugin:' + plugin + ':data', key, value, callback

	# "Convenience" functions that help get and set data...  or something.

	getBio: (callback) ->
		@getInfo 'bio', callback

	getCustomDisplayName: (callback) ->
		@getInfo 'custom_display_name', callback

	getCleanDisplayName: (callback) ->
		await @getInfo 'display_name', defer err, data

		if !data
			data = @getName()

		callback err, data

	getDisplayName: (callback) ->
		await
			@getCleanDisplayName defer err, cleanName
			@getCustomDisplayName defer err2, customName
			@isSupporter defer err3, isSupporter

		if !err2 and customName?
			callback err2, customName
		else if @isAdmin()
			callback err, '✜ ' + cleanName
		else if isSupporter
			callback err, '❤ ' + cleanName
		else
			callback err, cleanName

	getEmail: (callback) ->
		@getInfo 'email', callback

	getLogo: (callback) ->
		await @getInfo 'logo', defer err, data
		if err || !data?
			callback false, 'http://static-cdn.jtvnw.net/jtv_user_pictures/xarth/404_user_150x150.png'
		else
			callback err, data

	getProfileBanner: (callback) ->
		@getInfo 'profileBanner', callback

	setBio: (bio, callback) ->
		@setInfo 'bio', bio, callback

	setDisplayName: (name, callback) ->
		@setInfo 'display_name', name, callback

	setEmail: (email, callback) ->
		await Mikuia.Database.hset 'mikuia:emails', email, @getName(), defer whatever
		@setInfo 'email', email, callback

	setLogo: (logo, callback) ->
		@setInfo 'logo', logo, callback

	setProfileBanner: (profileBanner, callback) ->
		@setInfo 'profileBanner', profileBanner, callback

	setId: (id, callback) =>
		await Mikuia.Database.hset 'mikuia:ids', id, @getName(), defer err, whatever
		@setInfo 'id', id, callback

	# Moderatoring (LOL)

	isModOf: (channel, callback) ->
		if channel == @getName()
			return true
		else
			moderators = Mikuia.Chat.mods channel
			return moderators? && @getName() in moderators

	# :D

	updateAvatar: (callback) ->
		randomNumber = Math.floor(Math.random() * 10000000)
		await @getInfo 'logo', defer err, logo
		if !err && logo.indexOf('http://') > -1
			avatarFolder = 'web/public/img/avatars'
			fs.mkdir avatarFolder if not fs.existsSync avatarFolder
			path = avatarFolder + '/' + @getName() + '.jpg'
			r = request.get(logo).pipe fs.createWriteStream path
			r.on 'finish', ->
				gm(path).resize(64, 64).write(path, (err) ->
					callback err
				)
		else
			callback true

	# Levels

	addExperience: (channel, experience, activity, type, callback) =>
		await @isBot defer err, isBot
		if not isBot
			await @getLevel channel, defer err, level
			if activity < 1 || !activity? || isNaN activity
				experience = 0

			otherChannel = new Mikuia.Models.Channel channel
			await otherChannel.getSetting 'base', 'disableLevels', defer err, disableLevels

			if not disableLevels
				await
					@_hincrby 'experience', channel, experience, defer err, data
					@getLevel channel, defer err, newLevel

					@updateTotalLevel defer whatever

					otherChannel.getSetting 'base', 'announceLevels', defer err, announceLevels
					otherChannel.getSetting 'base', 'announceLimit', defer err2, announceLimit

				payload =
					timestamp: Math.floor((new Date()).getTime() / 1000)
					channel: channel
					experience: experience
					levelUp: false
					newLevel: null
					type: type

				if newLevel > level
					payload.levelUp = true
					payload.newLevel = newLevel

				# await Mikuia.Database.lpush 'channel:' + @getName() + ':experience:history', JSON.stringify(payload), defer whatever

				if not err and newLevel > level
					if announceLevels and not err2 and newLevel % announceLimit == 0 and activity > 0
						await @getDisplayName defer err, displayName
						await otherChannel.getDisplayName defer err, otherName
						Mikuia.Chat.sayUnfiltered channel, '.me > ' + displayName + ' just advanced to ' + otherName + ' Level ' + newLevel + '!'

					Mikuia.Events.emit 'levels.levelup',
						username: @getName()
						displayName: displayName
						channel: channel
						level: newLevel

		else
			await @updateTotalLevel defer whatever

		callback false

	getLevel: (channel, callback) =>
		await @getExperience channel, defer err, data
		if !err && data?
			callback false, Mikuia.Tools.getLevel(data)
		else
			callback false, 0

	getTotalLevel: (callback) =>
		await @getInfo 'level', defer err, data
		if err || !data?
			callback false, 0
		else
			callback false, data

	getExperience: (channel, callback) =>
		@_hget 'experience', channel, callback

	getAllExperience: (callback) =>
		await @_hgetall 'experience', defer err, data

		sortable = []
		for channel, experience of data
			sortable.push [channel, experience]
		sortable.sort (a,b) -> b[1] - a[1]

		callback err, sortable

	getTotalExperience: (callback) =>
		await @getInfo 'experience', defer err, data
		if err || !data?
			callback false, 0
		else
			callback false, data

	updateTotalLevel: (callback) =>
		totalExperience = 0

		await
			@getAllExperience defer err, experience
			@isBanned defer err, isBanned
			@isBot defer err, isBot

		if isBot or isBanned
			await @_del 'experience', defer err

		for data in experience
			if isBot or isBanned
				data[1] = 0

			totalExperience += parseInt data[1]
			await Mikuia.Database.zadd 'levels:' + data[0] + ':experience', data[1], @getName(), defer err, whatever

		totalLevel = Mikuia.Tools.getLevel totalExperience

		await
			@setInfo 'level', totalLevel, defer whatever, whatever
			@setInfo 'experience', totalExperience, defer whatever, whatever
			Mikuia.Database.zadd 'mikuia:experience', totalExperience, @getName(), defer whatever, whatever
			Mikuia.Database.zadd 'mikuia:levels', totalLevel, @getName(), defer whatever, whatever

		callback totalLevel

	# Donator / Supporter stuff

	getSupporterStart: (callback) =>
		@getInfo 'supporterStart', callback

	getSupporterStatus: (callback) ->
		Mikuia.Database.zscore 'mikuia:supporters', @getName(), callback

	isDonator: (callback) ->
		await Mikuia.Database.zscore 'mikuia:donators', @getName(), defer err, data
		callback err, (data? && data >= 10)

	isSupporter: (callback) ->
		await @getSupporterStatus defer err, data
		callback err, (data > new Date().getTime() / 1000)

	# Badges

	addBadge: (badgeId, callback) =>
		await @_sadd 'badges', badgeId, defer err, data
		await Mikuia.Database.sadd 'badge:' + badgeId + ':members', @getName(), defer err2, data2
		callback err, data

	getBadges: (callback) =>
		@_smembers 'badges', callback

	getBadgesWithInfo: (callback) =>
		await @getBadges defer err, data

		badgeInfo = {}
		for badgeId in data
			Badge = new Mikuia.Models.Badge badgeId

			await Badge.getAll defer err, badgeInfo[badgeId]

		callback err, badgeInfo

	removeBadge: (badgeId, callback) =>
		await @_srem 'badges', badgeId, defer err, data
		await Mikuia.Database.srem 'badge:' + badgeId + ':members', @getName(), defer err2, data2
		callback err, data
