module.exports = (req, res) =>
	if req.params.username?

		if req.params.channel?
			User = new Mikuia.Models.Channel req.params.username
			Channel = new Mikuia.Models.Channel req.params.channel

			await Channel.exists defer err, exists
			if !err and exists

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
			User = new Mikuia.Models.Channel req.params.username

			await User.exists defer err, exists
			if !err and exists

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