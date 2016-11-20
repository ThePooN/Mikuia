cli = require 'cli-color'

# chatActivity[viewer][channel]
chatActivity = {}
# lastMessage[viewer]
lastMessage = {}

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	liveChannel = new Mikuia.Models.Channel to
	await liveChannel.isLive defer err, live

	if live
		Channel = new Mikuia.Models.Channel user.username
		await
			Channel.isBanned defer err, isBanned
			Channel.isLevelDisabled defer err, isLevelDisabled

		if not isBanned and not isLevelDisabled
			gibePoints = user.username not of lastMessage or new Date().getTime() / 1000 > lastMessage[user.username] + 60

			chatActivity[user.username] ?= {}
			chatActivity[user.username][liveChannel.getName()] = 10

			if gibePoints and user.username isnt to.replace '#', ''
				await Channel.addExperience to.replace('#', ''), Math.round(Math.random() * 1), chatActivity[user.username][liveChannel.getName()], 'chat', defer whatever

				lastMessage[user.username] = new Date().getTime() / 1000

updateLevels = () ->
	# Check the time of a last level update
	await Mikuia.Database.get 'mikuia:lastUpdate', defer err, time
	seconds = (((new Date()).getTime() / 1000) - parseInt(time))

	# Calculate a multiplier (should always be close to 1x, but shit happens)
	multiplier = Math.round(seconds / 60)
	Mikuia.Log.info cli.yellowBright('Levels') + ' / ' + cli.whiteBright('Updating levels with a ') + cli.yellowBright(multiplier + 'x') + cli.whiteBright(' multiplier... (') + cli.yellowBright(Math.floor(seconds) + 's') + cli.whiteBright(' since last update)')

	if !err
		# Update the last... update time. Sigh.
		await Mikuia.Database.set 'mikuia:lastUpdate', parseInt((new Date()).getTime() / 1000), defer err2, response

		# We'll need this object to remember active channel statuses, I guess.
		viewers = {}

		# Let's get a whole list of live streams from the database.
		await Mikuia.Streams.getAll defer err, streams
		if not err and streams?

			# For every live stream, let's get a whole chatter list... or something. I hate writing comments.
			for stream in streams
				chatters = Mikuia.Chat.getChatters stream

				# Who cares if they're mods or not.
				# Categories: moderators, staff, admins, global_mods, viewers.
				# Not like anyone will ever need this though.
				for categoryName, category of chatters
					for chatter in category

						# If that's the first time someone is appearing on the list, make an empty array for them.
						if !viewers[chatter]?
							viewers[chatter] = []

						# Let's put the stream on the viewers' list.
						viewers[chatter].push stream

			# Okay, so by now, we should have a huge object of people with their watched streams
			# Something like this:
			# viewers = {
			# 	nikersify: [
			# 		'kaceytron',
			# 		'kittyplaysgames'
			# 	],
			# 	hatsuney: [
			# 		'jeffdee'
			# 	]
			# }

			# Now, for every viewer, we need to grant them POINTS.
			for viewer, channels of viewers
				Channel = new Mikuia.Models.Channel viewer

				# Self-explanatory.
				activeChannels = 0
				pointsToAdd = 0

				# Check if we know anything about any kind of viewer activity.
				if chatActivity[viewer]?

					# For every channel the viewer was active in, check if the activity value is higher than 0 and if the channel is still live.
					for activityChannel, activityValue of chatActivity[viewer]
						if activityValue > 0 and activityChannel in streams
							activeChannels++

				if activeChannels == 1
					# RNG HYPE
					pointsToAdd = Math.round(Math.random() * 1) + 4
				else if activeChannels == 2
					pointsToAdd = 2
				else if activeChannels == 3
					pointsToAdd = 1

				pointsToAdd *= multiplier

				# Just a little happy failsafe in case everything goes wrong.
				# We don't want level 30000 to happen again...
				if pointsToAdd > 20
					pointsToAdd = 20

				# Check if there are any points to add and if the streamer isn't the same as the viewer!
				for channel in channels

					# If the viewer doesn't have any activity on that channel, set the value to 0.
					chatActivity[viewer] ?= {}
					chatActivity[viewer][channel] ?= 0

					if pointsToAdd > 0 and viewer isnt channel
						# That method should be moved out of Channel... sigh.
						await Channel.addExperience channel, pointsToAdd, chatActivity[viewer][channel], 'stream', defer whatever

					# Lower the viewer activity by the multiplier.
					chatActivity[viewer][channel] -= multiplier

# Update levels every minute :D
setInterval () =>
	updateLevels()
, 60000
updateLevels()
