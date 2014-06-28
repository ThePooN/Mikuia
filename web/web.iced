bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
express = require 'express'
fs = require 'fs'
morgan = require 'morgan'
passport = require 'passport'
path = require 'path'
session = require 'express-session'

RedisStore = require('connect-redis')(session)
TwitchStrategy = require('passport-twitchtv').Strategy

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

store = new RedisStore
	host: Mikuia.settings.redis.host
	port: Mikuia.settings.redis.port
	db: Mikuia.settings.redis.db
	pass: Mikuia.settings.redis.options.auth_pass

routes = {}
app = express()

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

passport.use new TwitchStrategy
	clientID: Mikuia.settings.twitch.key
	clientSecret: Mikuia.settings.twitch.secret
	callbackURL: Mikuia.settings.twitch.callbackURL
	scope: 'user_read'
, (accessToken, refreshToken, profile, done) ->
	process.nextTick () ->
		return done null, profile

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
#app.use morgan 'dev'
app.use express.static __dirname + '/public'
app.use cookieParser 'oijt09j4g09qjg90q3jk90q3'
app.use bodyParser()
app.use session
	secret: 'oijt09j4g09qjg90q3jk90q3'
	store: store
app.use passport.initialize()
app.use passport.session()
app.use (req, res, next) ->
	res.locals.path = req.path
	res.locals.user = req.user
	next()

fileList = fs.readdirSync 'web/routes'
for file in fileList
	filePath = path.resolve('web/routes/' + file)
	routes[file.replace('.iced', '')] = require filePath

app.get '/', routes.index
app.get '/dashboard', checkAuth, routes.dashboard
app.get '/dashboard/settings', checkAuth, routes.settings.settings
app.get '/dashboard/settings/disable', checkAuth, routes.settings.disable
app.get '/dashboard/settings/enable', checkAuth, routes.settings.enable
app.get '/login', routes.login
app.get '/logout', (req, res) ->
	req.logout()
	res.redirect '/'

app.get '/auth/twitch', passport.authenticate('twitchtv', { scope: [ 'user_read' ] })
app.get '/auth/twitch/callback', passport.authenticate('twitchtv', { failureRedirect: '/login' }), (req, res) ->
	res.redirect '/dashboard'

app.listen 2912