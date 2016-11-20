module.exports = (req, res) ->
	Badge = new Mikuia.Models.Badge req.params.badgeId

	await Badge.exists defer err, exists

	if exists
		memberData = {}

		await
			Badge.getAll defer err, data
			Badge.getMembers defer err, members
			Mikuia.Database.zcount 'mikuia:experience', '-inf', '+inf', defer err, uniqueChatters

		for member in members
			Channel = new Mikuia.Models.Channel member
			memberData[member] = {}
			await
				Channel.getCleanDisplayName defer err, memberData[member].displayName
				Channel.getLogo defer err, memberData[member].logo

		res.render 'community/badge',
			titlePath: ['Badge', data.displayName]
			Badge: data
			badgeId: req.params.badgeId
			members: members
			memberData: memberData
			uniqueChatters: uniqueChatters
	else
		res.render 'community/error',
			titlePath: ['Error']
			error: 'Badge does not exist.'
