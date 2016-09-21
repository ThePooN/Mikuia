bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
express = require 'express.io'
fs = require 'fs-extra'
gm = require 'gm'
moment = require 'moment'
morgan = require 'morgan'
passport = require 'passport'
path = require 'path'
request = require 'request'
rstring = require 'random-string'
session = require 'express-session'

RedisStore = require('connect-redis')(session)
TwitchStrategy = require('passport-twitchtv').Strategy

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	else
		req.session.redirectTo = req.path
		res.redirect '/login'

store = new RedisStore
	host: Mikuia.settings.redis.host
	port: Mikuia.settings.redis.port
	db: Mikuia.settings.redis.db
	pass: Mikuia.settings.redis.options.auth_pass

routes = {}
module.exports = app = express()
app.http().io()

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

twitchStrategy = new TwitchStrategy
	clientID: Mikuia.settings.twitch.key
	clientSecret: Mikuia.settings.twitch.secret
	callbackURL: Mikuia.settings.twitch.callbackURL
	scope: 'user_read'
, (accessToken, refreshToken, profile, done) ->
	process.nextTick () ->
		return done null, profile

twitchStrategy.authorizationParams = => { force_verify: true }

passport.use twitchStrategy

if opbeat?
	app.use opbeat.middleware.express()

if Mikuia.settings.sentry.enable
	raven = require 'raven'
	app.use raven.middleware.express Mikuia.settings.sentry.dsn
else
	iced.catchExceptions()

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
app.use express.static __dirname + '/public'
app.use cookieParser 'oijt09j4g09qjg90q3jk90q3'
app.use bodyParser.urlencoded
	extended: true
app.use bodyParser.json()
app.use morgan 'dev'
app.use session
	resave: false
	saveUninitialized: true
	secret: 'oijt09j4g09qjg90q3jk90q3'
	store: store
app.use passport.initialize()
app.use passport.session()
app.use express.vhost 'api.dev.mikuia.tv', require('./api').app
app.use (req, res, next) ->
	res.locals.Mikuia = Mikuia
	res.locals.moment = moment
	res.locals.path = req.path
	res.locals.user = req.user

	isBanned = false
	pages = []
	tracker = {}
	if req.user
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel.isBanned defer err, isBanned

		if !isBanned and req.path.indexOf('/dashboard') == 0
			await Channel.isLive defer err, isLive

			if isLive
				await
					Channel.trackGet 'viewers', defer err, tracker.viewers
					Channel.trackGet 'chatters', defer err, tracker.chatters
			await Channel.trackGet 'commands', defer err, tracker.commands
			await Channel.trackGet 'followers', defer err, tracker.followers
			await Channel.trackGet 'messages', defer err, tracker.messages
			await Channel.trackGet 'views', defer err, tracker.views

			pagePlugins = Mikuia.Element.getAll 'dashboardPagePlugin'
			for pagePlugin in pagePlugins || []
				await Channel.isPluginEnabled pagePlugin.plugin, defer err, enabled
				if !err && enabled
					for pagePath, {name, icon} of pagePlugin.pages
						pages.push {
							name, icon,
							path: '/dashboard/plugins/' + pagePlugin.plugin + pagePath
						}

	if !isBanned
		res.locals.pages = pages
		res.locals.tracker = tracker
		next()
	else
		res.send 'This account ("' + req.user.username + '") has been permanently banned from using Mikuia.'

fs.mkdirs 'web/public/img/avatars'

routeList =
	community: 'web/routes/community'
	dashboard: 'web/routes/dashboard'

for routeName, routeDir of routeList
	routes[routeName] = {}
	fileList = fs.readdirSync routeDir
	for file in fileList
		filePath = path.resolve routeDir + '/' + file
		routes[routeName][file.replace('.iced', '')] = require filePath

routes.login = require './routes/login'

app.get '/dashboard', checkAuth, routes.dashboard.index
app.get '/dashboard/commands', checkAuth, routes.dashboard.commands.commands
app.get '/dashboard/commands/settings/:name', checkAuth, routes.dashboard.commands.settings
app.get '/dashboard/plugins', checkAuth, routes.dashboard.plugins.plugins
app.get '/dashboard/settings', checkAuth, routes.dashboard.settings.settings
app.get '/login', routes.login
app.get '/logout', (req, res) ->
	req.logout()
	res.redirect '/'

app.post '/dashboard/commands/add', checkAuth, routes.dashboard.commands.add
app.post '/dashboard/commands/remove', checkAuth, routes.dashboard.commands.remove
app.post '/dashboard/commands/save/:name', checkAuth, routes.dashboard.commands.save
app.post '/dashboard/plugins/toggle', checkAuth, routes.dashboard.plugins.pluginToggle
app.post '/dashboard/settings/save/:name', checkAuth, routes.dashboard.settings.save
app.post '/dashboard/settings/toggle', checkAuth, routes.dashboard.settings.toggle

app.get '/', routes.community.index
app.get '/about', routes.community.about
app.get '/badge/:badgeId', routes.community.badge
# app.get '/contribute', routes.community.contribute
app.get '/guide', routes.community.guides.quickstart
app.get '/guides/csgo', routes.community.guides.csgo
app.get '/guides/levels', routes.community.guides.levels
app.get '/guides/osu', routes.community.guides.osu
app.get '/guides/quickstart', routes.community.guides.quickstart
app.get '/leagues', routes.community.leagues.index
app.get '/leagues/leaderboards', routes.community.leagues.index
# app.get '/levels', routes.community.levels
# app.get '/levels/:userId', routes.community.levels
app.post '/search', routes.community.search
app.get '/settings', checkAuth, routes.community.settings.index
app.post '/settings/move', routes.community.settings.move
app.post '/settings/move/accept', routes.community.settings.moveAccept
app.post '/settings/move/reject', routes.community.settings.moveReject
app.get '/streams', routes.community.streams
app.get '/supporter', routes.community.supporter
app.get '/user/:userId', routes.community.user
app.get '/user/:userId/:subpage', routes.community.user

app.get '/auth/twitch', passport.authenticate('twitchtv', { scope: [ 'user_read' ] })
app.get '/auth/twitch/callback', (req, res, next) =>
	passport.authenticate('twitchtv', (err, user, info) ->
		if err
			return res.render 'community/error',
				error: err
		if !user
			return res.redirect '/login'
		req.logIn user, (err) =>
			if err
				return res.render 'community/error',
					error: err

			Channel = new Mikuia.Models.Channel user.username
			await
				Channel.setDisplayName user._json.display_name, defer err, data
				Channel.setBio user._json.bio, defer err, data
				Channel.setEmail user.email, defer err, data
				Channel.enablePlugin 'base', defer err, data
				Channel.getInfo 'key', defer err, key

			if user._json.logo? && user._json.logo.indexOf('http') == 0
				await Channel.setLogo user._json.logo, defer err, data
			else
				await Channel.setLogo 'http://static-cdn.jtvnw.net/jtv_user_pictures/xarth/404_user_150x150.png', defer err, data

			if !key?
				key = rstring
					length: 20
				await Channel.setInfo 'key', key

			if req.session.redirectTo?
				res.redirect req.session.redirectTo
			else
				res.redirect '/'

			await Channel.updateAvatar defer err, whatever
	)(req, res, next)

app.get '/:checkword/:subpage?*', (req, res, next) =>
	Channel = new Mikuia.Models.Channel req.params.checkword

	await Channel.exists defer err, exists
	if exists
		req.params.userId = Channel.getName()
		routes.community.user req, res
	else
		next()

app.listen Mikuia.settings.web.port
