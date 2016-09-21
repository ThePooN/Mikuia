module.exports = (req, res) ->
	game = ''

	if !req.param 'sortMethod'
		sortMethod = 'viewers'
	else
		sortMethod = req.param 'sortMethod'

	sortLeaderboard = new Mikuia.Models.Leaderboard sortMethod

	await Mikuia.Streams.getAllSorted sortMethod, defer sorting, streams
	await sortLeaderboard.getDisplayHtml defer err, displayHtml

	leaderboards = {}
	lbList = Mikuia.Element.getAll 'leaderboards'
	for lbName in lbList
		lb = new Mikuia.Models.Leaderboard lbName
		await lb.getDisplayName defer err, displayName
		leaderboards[lbName] = displayName

	res.render 'community/streams',
		titlePath: ['Streams']
		displayHtml: displayHtml
		leaderboards: leaderboards
		sorting: sorting
		sortMethod: sortMethod
		streams: streams
0Looking
