module.exports = (req, res) ->
	await Mikuia.Database.hgetall 'mikuia:stream:' + req.params.username, defer err, stream

	if not err and stream?
		res.json
			stream: stream
	else
		res.send 404