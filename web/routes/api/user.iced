module.exports = (req, res) ->
	if req.params.username?
		Channel = new Mikuia.Models.Channel req.params.username

		await Channel.exists defer err, exists
		if err or not exists
			res.send 404
		else

			await Channel.getAll defer err, user
			await Channel.getDisplayName defer err, user.displayName
				# Channel.getLogo defer err, user.logo
				# Channel.getProfileBanner defer err, user.profileBanner

			if !user.logo
				user.logo = 'http://static-cdn.jtvnw.net/jtv_user_pictures/xarth/404_user_300x300.png'

			res.json
				user:
					displayName: user.displayName
					logo: user.logo
					profileBanner: user.profileBanner
					bio: user.bio
					level: parseInt user.level
					experience: parseInt user.experience
	else
		if req.user
			console.log req.user

			res.json
				auth: true
				id: req.user.id
				username: req.user.username
				displayName: req.user.displayName
				logo: req.user._json.logo
		else
			res.json
				auth: false

	# if not req.params.userId?
	# 	res.render 'community/error',
	# 		error: 'No user specified.'
	# else
	# 	Channel = new Mikuia.Models.Channel req.params.userId

	# 	await Channel.exists defer err, exists
	# 	if err
	# 		res.render 'community/error',
	# 			titlePath: ['Error']
	# 			error: err
	# 	else if not exists
	# 		res.render 'community/error',
	# 			titlePath: ['Error']
	# 			error: 'User does not exist.'
	# 	else

	# 		channel =
	# 			name: Channel.getName()
	# 		displayNames = {}
	# 		ranks = {}

	# 		await
	# 			Channel.getAllExperience defer err, channel.experience
	# 			Channel.getBadgesWithInfo defer err, channel.badges
	# 			Channel.getBio defer err, channel.bio
	# 			Channel.getCleanDisplayName defer err, channel.display_name
	# 			Channel.getCommands defer err, commands
	# 			Channel.getEnabledPlugins defer err, channel.plugins
	# 			Channel.getLogo defer err, channel.logo
	# 			Channel.getProfileBanner defer err, channel.profileBanner
	# 			Channel.getSetting 'coins', 'name', defer err, coinName
	# 			Channel.getSetting 'coins', 'namePlural', defer err, coinNamePlural
	# 			Channel.getTotalLevel defer err, channel.level
	# 			Channel.isBanned defer err, channel.isBanned
	# 			Channel.isBot defer err, channel.isBot
	# 			Channel.isLevelDisabled defer err, channel.isLevelDisabled
	# 			Channel.isLive defer err, channel.isLive

	# 		for data in channel.experience
	# 			chan = new Mikuia.Models.Channel data[0]
	# 			await chan.getDisplayName defer err, displayNames[data[0]]
	# 			await Mikuia.Database.zrevrank 'levels:' + data[0] + ':experience', Channel.getName(), defer err, ranks[data[0]]

	# 		for name, rank of ranks
	# 			ranks[name]++

	# 		if req.params.subpage?
	# 			switch req.params.subpage
	# 				when 'levels'
	# 					res.render 'community/userLevels',
	# 						titlePath: ['Profile', channel.display_name, 'Levels']
	# 						Channel: channel
	# 						displayNames: displayNames
	# 						ranks: ranks
	# 				when 'inventory'
	# 					await
	# 						Mikuia.Items.getUserInventory Channel.getName(), defer err, items

	# 					res.render 'community/inventory',
	# 						titlePath: ['Profile', channel.display_name, 'Inventory']
	# 						Channel: channel
	# 						items: items
	# 				else
	# 					res.render 'community/error',
	# 						titlePath: ['Error']
	# 						error: 'No subpage specified.'
	# 		else
	# 			channel.commands = []
	# 			sorting = []
	# 			for commandName, commandHandler of commands
	# 				sorting.push commandName

	# 			sorting.sort()
	# 			for command in sorting
	# 				if Mikuia.Plugin.getHandler(commands[command])?.description?
	# 					description = Mikuia.Plugin.getHandler(commands[command]).description
	# 					codeText = false

	# 					await Channel.getCommandSettings command, true, defer err, settings

	# 					if commands[command] == 'base.dummy'
	# 						description = settings.message
	# 						codeText = true

	# 					channel.commands.push
	# 						name: command
	# 						description: description
	# 						plugin: Mikuia.Plugin.getHandler(commands[command]).plugin
	# 						pluginName: Mikuia.Plugin.getManifest(Mikuia.Plugin.getHandler(commands[command]).plugin).name
	# 						settings: settings
	# 						coin:
	# 							coinName: coinName
	# 							coinNamePlural: coinNamePlural
	# 						codeText: codeText

	# 			if channel.isLive
	# 				await Mikuia.Streams.get Channel.getName(), defer err, channel.stream

	# 			splashButtons = []
	# 			for element in Mikuia.Element.getAll 'userPageSplashButton'
	# 				if channel.plugins.indexOf(element.plugin) > -1
	# 					splashButtons = splashButtons.concat element

	# 			for element, i in splashButtons
	# 				for button, j in element.buttons
	# 					if button.setting?
	# 						await Channel.getSetting element.plugin, button.setting, defer err, value
	# 						if value
	# 							button.link = button.linkFunction value
	# 						else
	# 							button.link = false

	# 			res.render 'community/user',
	# 				titlePath: ['Profile', channel.display_name]
	# 				Channel: channel
	# 				displayNames: displayNames
	# 				splashButtons: splashButtons
