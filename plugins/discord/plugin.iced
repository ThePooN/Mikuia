cli = require 'cli-color'
Discord = require 'discord.io'

users = {}

if Mikuia.settings.plugins.discord?.token? and Mikuia.settings.plugins.discord.token != 'BOT_USER_TOKEN'
	discord = new Discord.Client
		token: Mikuia.settings.plugins.discord.token
		autorun: true

	discord.on 'disconnect', =>
		discord.connect()

	discord.on 'err', (error) ->
		Mikuia.Log.error cli.blueBright('Discord') + ' / ' + cli.whiteBright('Error:' + error)

	discord.on 'ready', (rawEvent) ->
		Mikuia.Log.info cli.blueBright('Discord') + ' / ' + cli.whiteBright('Connected to Discord.')

		discord.setPresence
			idle_since: null
			game: 'discord.mikuia.tv'

	discord.on 'message', (user, userId, channelId, message, rawEvent) =>
		channel = discord.channels[channelId]

		if channel?.guild_id?
			serverId = channel.guild_id

			await Mikuia.Database.hget 'plugin:discord:servers', serverId, defer err, twitchChannel

			if !err and twitchChannel?
				Channel = new Mikuia.Models.Channel twitchChannel

				await
					Channel.isPluginEnabled 'discord', defer err2, isPluginEnabled
					Mikuia.Database.hget 'plugin:discord:users', userId, defer err3, twitchUser

				if !err2 and isPluginEnabled

					if twitchUser?
						user =
							username: twitchUser
							color: '#ffffff'
							subscriber: false
					else
						user = null

					Mikuia.Chat.handleMessage user, twitchChannel, message, 'discord',
						discordChannelId: channelId
						discordUserId: userId

	Mikuia.Events.on 'mikuia.say.custom', (data) =>
		switch data.target
			when 'discord'
				if data.details?.discordChannelId?
					discord.sendMessage
						to: data.details.discordChannelId
						message: '<@' + data.details.discordUserId + '>: ' + data.message

			when 'discord_private'
				discord.sendMessage
					to: data.details.discordUserId
					message: '**[' + data.channel + ']** ' + data.message

	Mikuia.Events.on 'mikuia.command.failure', (data) =>
		switch data.settings._target
			when 'discord'
				if data.details?.discordChannelId? and data.details?.discordUserId
					discord.sendMessage
						to: data.details.discordChannelId
						message: '<@' + data.details.discordUserId + '>: You need to link your account on ' + Mikuia.settings.plugins.discord.callbackBasePath + '/auth/discord to use this command.'

			when 'discord_private'
				discord.sendMessage
					to: data.details.discordUserId
					message: '**[' + data.to + ']** You need to link your account on ' + Mikuia.settings.plugins.discord.callbackBasePath + '/auth/discord to use this command.'