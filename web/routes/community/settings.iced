_ = require 'underscore'

module.exports =
	index: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		await
			Channel.getCleanDisplayName defer err, displayName
			Channel.getProfileBanner defer err, profileBanner
			Mikuia.Database.smembers 'channel:' + Channel.getName() + ':requests:move', defer err, moveRequests

		res.render 'community/settings',
			titlePath: ['Settings', displayName]
			displayName: displayName
			moveRequests: moveRequests
			profileBanner: profileBanner

	move: (req, res) ->
		if req.isAuthenticated() and req.body.username?
			Channel = new Mikuia.Models.Channel req.body.username

			if Channel.getName() != req.user.username
				await Channel.isLevelDisabled defer err, levelDisabled
				if not err and !levelDisabled
					await Mikuia.Database.sadd 'channel:' + Channel.getName() + ':requests:move', req.user.username, defer whatever

					res.send 'ok'
				else
					res.send 'fail'
			else
				res.send 'fail'
		else
			res.send 'epic fail'

	moveAccept: (req, res) ->
		if req.isAuthenticated() and req.body.username?
			Source = new Mikuia.Models.Channel req.body.username
			Target = new Mikuia.Models.Channel req.user.username

			await Mikuia.Database.sismember 'channel:' + Target.getName() + ':requests:move', Source.getName(), defer err, isMember
			if isMember
				await
					Mikuia.Database.srem 'channel:' + Target.getName() + ':requests:move', Source.getName(), defer whatever
					Mikuia.Database.sadd 'mikuia:levels:disabled', Source.getName(), defer whatever
					Mikuia.Database.zrevrange 'levels:' + Source.getName() + ':experience', 0, -1, 'withscores', defer err, rawLevels
					Source.getAllExperience defer err, experience

				levels = _.groupBy rawLevels, (a, b) => Math.floor b / 2

				for levelSeqId, levelData of levels
					username = levelData[0]
					xpAmount = parseInt levelData[1]
					Viewer = new Mikuia.Models.Channel username

					await
						Viewer.addExperience Target.getName(), xpAmount, 100, 'move_channel_' + Source.getName(), defer whatever
						Viewer.addExperience Source.getName(), xpAmount * -1, 100, 'move_channel_' + Target.getName(), defer whatever

				for userLevelData in experience
					username = userLevelData[0]
					xpAmount = parseInt userLevelData[1]

					if Target.getName() != username
						await Target.addExperience username, xpAmount, 100, 'move_user_' + Source.getName(), defer whatever

					await Source.addExperience username, xpAmount * -1, 100, 'move_user_' + Target.getName(), defer whatever

			res.send 'ok'
		else
			res.send 'fail'

	moveReject: (req, res) ->
		if req.isAuthenticated() and req.body.username?
			Target = new Mikuia.Models.Channel req.user.username

			await Mikuia.Database.srem 'channel:' + Target.getName() + ':requests:move', req.body.username, defer whatever
			res.send 'ok'
		else
			res.send 'fail'
