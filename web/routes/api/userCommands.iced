module.exports = (req, res) =>
	if req.params.username?

		Channel = new Mikuia.Models.Channel req.params.username

		await Channel.exists defer err, exists
		if !err and exists

			await
				Channel.getCommands defer err, commands
				Channel.getSetting 'coins', 'name', defer err, coinName
				Channel.getSetting 'coins', 'namePlural', defer err, coinNamePlural

			commandData = []
			sorting = []

			for commandName, commandHandler of commands
				sorting.push commandName

			sorting.sort()
			for command in sorting
				if Mikuia.Plugin.getHandler(commands[command])?.description?
					description = Mikuia.Plugin.getHandler(commands[command]).description
					codeText = false

					await Channel.getCommandSettings command, true, defer err, settings

					if commands[command] == 'base.dummy'
						description = settings.message
						codeText = true

						if settings._onlyBroadcaster or settings._onlyMods or settings._onlySubs or settings._coinCost or settings._minLevel
							description = null

					cleanSettings = {}

					if settings._onlyBroadcaster then cleanSettings._onlyBroadcaster = settings._onlyBroadcaster
					if settings._onlyMods then cleanSettings._onlyMods = settings._onlyMods
					if settings._onlySubs then cleanSettings._onlySubs = settings._onlySubs
					if settings._cooldown then cleanSettings._cooldown = parseInt settings._cooldown
					if settings._whisper then cleanSettings._whisper = settings._whisper
					if settings._coinCost then cleanSettings._coinCost = parseInt settings._coinCost
					if settings._minLevel then cleanSettings._minLevel = parseInt settings._minLevel

					commandData.push
						name: command
						handler: commands[command]
						description: description
						plugin: Mikuia.Plugin.getHandler(commands[command]).plugin
						pluginName: Mikuia.Plugin.getManifest(Mikuia.Plugin.getHandler(commands[command]).plugin).name
						settings: cleanSettings
						coin:
							coinName: coinName
							coinNamePlural: coinNamePlural
						codeText: codeText

			res.json
				commands: commandData

		else
			res.send 404

	else
		res.send 400