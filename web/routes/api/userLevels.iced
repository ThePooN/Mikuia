module.exports = (req, res) =>
	if req.params.username?
		if req.params.channel?
			await 
				Mikuia.Twitch.findChannel req.params.username, defer User
				Mikuia.Twitch.findChannel req.params.channel, defer Channel
			
			if User? and Channel?

				await
					Mikuia.Database.zrevrank 'levels:' + Channel.getName() + ':experience', User.getName(), defer err, rank
					Mikuia.Database.zscore 'levels:' + Channel.getName() + ':experience', User.getName(), defer err, experience

				# levels = []
				# for channel, experience of levelData
				# 	levels.push
				# 		username: channel
				# 		experience: parseInt experience
				# levels.sort (a,b) -> b.experience - a.experience


				res.json
					experience: parseInt experience
					rank: rank + 1
			else
				res.send 404

		else
			await Mikuia.Twitch.findChannel req.params.username, defer User

			if User?
				await Mikuia.Database.hgetall 'channel:' + User.getName() + ':experience', defer err, levelData

				levels = []
				for channel, experience of levelData
					levels.push
						username: channel
						experience: parseInt experience
				levels.sort (a,b) -> b.experience - a.experience

				res.json
					levels: levels
			else
				res.send 404
	else
		res.send 400