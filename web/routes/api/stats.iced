module.exports =
	levelHistory: (req, res) =>
		if req.params.username?

			if req.user?.username? and req.user.username is req.params.username
				console.log req.user

				limit = 50
				offset = 0

				if req.param 'limit'
					limit = Math.min(Math.max(0, parseInt(req.param('limit')) - 1), 100)

				if req.param 'offset'
					offset = Math.min(Math.max(0, parseInt(req.param('offset'))), 100)

				await Mikuia.Database.lrange 'channel:' + req.user.username + ':experience:history', offset, limit + offset, defer err, data

				for entry, i in data
					data[i] = JSON.parse entry

				res.json
					history: data
			else
				res.send 403



			# Channel = new Mikuia.Models.Channel req.params.username

			# await Channel.exists defer err, exists
			# if !err and exists
			# 	await
			# 		Channel.getTotalExperience defer err, totalExperience
			# 		Channel.getTotalLevel defer err, totalLevel
			# 		Mikuia.Database.zrevrank 'mikuia:experience', Channel.getName(), defer err, totalRank

			# 	res.json
			# 		experience: parseInt totalExperience
			# 		level: parseInt totalLevel
			# 		rank: parseInt(totalRank) + 1
			# else
			# 	res.send 404






		else
			res.send 400

	userLevels: (req, res) =>
		if req.params.username?
			Channel = new Mikuia.Models.Channel req.params.username

			await Channel.exists defer err, exists
			if !err and exists
				await
					Channel.getTotalExperience defer err, totalExperience
					Channel.getTotalLevel defer err, totalLevel
					Mikuia.Database.zrevrank 'mikuia:experience', Channel.getName(), defer err, totalRank

				res.json
					experience: parseInt totalExperience
					level: parseInt totalLevel
					rank: parseInt(totalRank) + 1
			else
				res.send 404
		else
			res.send 400