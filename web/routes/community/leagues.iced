module.exports =
	index: (req, res) ->
		userInfo = {}

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username

			await
				Mikuia.Database.zrevrank 'leaderboard:1v1rating:scores', Channel.getName(), defer err, userInfo.rank
				Mikuia.Leagues.getFightCount Channel.getName(), defer err, userInfo.fightCount
				Mikuia.Leagues.getFightCountLost Channel.getName(), defer err, userInfo.fightsLost
				Mikuia.Leagues.getFightCountWon Channel.getName(), defer err, userInfo.fightsWon
				Mikuia.Leagues.getRating Channel.getName(), defer err, userInfo.rating

		await Mikuia.Database.zrevrange 'leaderboard:1v1rating:scores', 0, 99, 'withscores', defer err, ranks

		channels = Mikuia.Tools.chunkArray ranks, 2
		displayNames = {}
		fights = {}
		isStreamer = {}
		logos = {}

		for data in channels
			if data.length > 0
				channel = new Mikuia.Models.Channel data[0]
				rating = data[1]

				await
					channel.isStreamer defer err, isStreamer[data[0]]
					channel.getCleanDisplayName defer err, displayNames[data[0]]
					channel.getLogo defer err, logos[data[0]]
					Mikuia.Leagues.getFightCount channel.getName(), defer err, fights[data[0]]

		res.render 'community/leagues',
			titlePath: ['Leagues', 'Leaderboards']
			channels: channels
			displayNames: displayNames
			fights: fights
			isStreamer: isStreamer
			logos: logos
			userInfo: userInfo
