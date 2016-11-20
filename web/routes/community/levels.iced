module.exports = (req, res) ->
	if req.params.userId?
		Channel = new Mikuia.Models.Channel req.params.userId

		await Channel.exists defer err, exists
		if !err
			if exists
				await Channel.getCleanDisplayName defer err, displayName
				await Channel.getProfileBanner defer err, profileBanner
				await Mikuia.Database.zrevrange 'levels:' + Channel.getName() + ':experience', 0, 99, 'withscores', defer err, ranks

				channels = Mikuia.Tools.chunkArray ranks, 2
				displayNames = {}
				experience = null
				isStreamer = {}
				logos = {}
				rank = null

				for data in channels
					if data.length > 0
						channel = new Mikuia.Models.Channel data[0]
						experience = data[1]

						await
							channel.isStreamer defer err, isStreamer[data[0]]
							channel.getCleanDisplayName defer err, displayNames[data[0]]
							channel.getLogo defer err, logos[data[0]]

				if req.isAuthenticated()
					channel = new Mikuia.Models.Channel req.user.username
					await
						channel.getExperience Channel.getName(), defer err, experience
						Mikuia.Database.zrevrank 'levels:' + Channel.getName() + ':experience', req.user.username, defer err, rank

				res.render 'community/levelsUser',
					titlePath: ['Levels', displayName]
					channels: channels
					displayName: displayName
					displayNames: displayNames
					experience: experience
					isStreamer: isStreamer
					logos: logos
					profileBanner: profileBanner
					rank: rank + 1
			else
				res.render 'community/error',
					error: 'Channel does not exist.'
		else
			res.render 'community/error',
				error: err

	else
		await Mikuia.Streams.getAll defer err, allStreams

		displayNames = {}
		experience = {}
		logos = {}
		ranks = {}
		streams = Mikuia.Tools.fillArray allStreams, 10
		totalLevel = null
		totalRank = null
		userCount = {}

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username

			await
				Channel.getAllExperience defer err, data
				Channel.getTotalExperience defer err, totalExperience
				Channel.getTotalLevel defer err, totalLevel
				Mikuia.Database.zrevrank 'mikuia:experience', Channel.getName(), defer err, totalRank

			for md in data
				experience[md[0]] = md[1]

				chan = new Mikuia.Models.Channel md[0]
				await chan.getCleanDisplayName defer err, displayNames[md[0]]

				if md[0] in allStreams
					streams.push md[0]

			for stream in streams
				await Mikuia.Database.zrevrank 'levels:' + stream + ':experience', req.user.username, defer err, ranks[stream]

			for name, rank of ranks
				ranks[name]++

		for stream in streams
			if stream?
				chan = new Mikuia.Models.Channel stream
				await chan.getCleanDisplayName defer err, displayNames[stream]
				await Mikuia.Database.zcard 'levels:' + stream + ':experience', defer err, userCount[stream]

		res.render 'community/levels',
			titlePath: ['Levels']
			displayNames: displayNames
			experience: experience
			level: totalLevel
			logos: logos
			ranks: ranks
			rawExperience: data
			streams: streams
			totalExperience: totalExperience
			totalRank: totalRank + 1
			userCount: userCount