import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Col, Grid, Row} from 'react-bootstrap'
import {translate, Interpolate} from 'react-i18next'
import {LinkContainer} from 'react-router-bootstrap'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockUser from '../components/community/CardBlockUser'
import ErrorPage from '../components/community/ErrorPage'
import LevelCircle from '../components/community/LevelCircle'

import {Authenticated, NotAuthenticated} from '../components/Auth'
import Tools from '../tools'

var LevelsChannel = React.createClass({
	contextTypes: {
		auth: React.PropTypes.bool,
		user: React.PropTypes.object
	},

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('splash', false)
			self.props.setHeaderOption('title', [self.props.t('header:link.levels'), self.state.user.displayName])
		})

		this.poll()

		$(window).scroll(function() {
			if($('body').height() <= ($(window).height() + $(window).scrollTop())) {
				if(!self.state.loading) {
					self.setState({
						loading: true
					})
					self.loadLevels(self.state.offset)
				}
			}
		})

	},

	componentWillUnmount: function() {
		$(window).unbind('scroll')

		this.props.resetHeaderOptions()
	},

	getInitialState: function() {
		return {
			users: [],
			user: {
				displayName: this.props.params.username,
				logo: ''
			},
			stats: {
				experience: null
			},
			offset: 0,
			error: false,
			loading: true
		}
	},

	loadLevels: function(offset) {
		var self = this
		var users = self.state.users
		$.get('/api/levels/' + this.props.params.username + '?limit=50&offset=' + offset).success(function(data) {
			for(var userId in data.users) {
				users.push(data.users[userId])
			}

			self.setState({
				users: users,
				offset: self.state.offset + 50,
				loading: false
			})

		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				loading: false,
				users: users
			})
		})
	},

	poll: function() {
		var self = this
		self.setState({
			loading: true
		})

		$.get('/api/user/' + this.props.params.username).success(function(data) {
			self.setState({
				user: data.user
			})
			self.props.setHeaderOption('background', data.user.profileBanner)
			self.props.setHeaderOption('title', [self.props.t('header:link.levels'), data.user.displayName])

		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				user: {}
			})
		})

		this.pollStats()
		this.loadLevels(0)
	},

	pollStats: function() {
		var self = this
		if(this.context.auth) {
			$.get('/api/user/' + this.context.user.username + '/levels/' + this.props.params.username).success(function(data) {
				self.setState({
					stats: data
				})
			})
		} else if(this.context.auth == null) {
			setTimeout(function() {
				self.pollStats()
			}, 100)
		}
	},

	render: function() {
		const {t} = this.props
		return (
			<Grid>
				<Choose>
					<When condition={!this.state.error}>
						<div className="mikuia-page-padding">
							<Row>
								<Col md={8}>
									<h1 className="mikuia-page-header-text text-white">
										<Interpolate i18nKey="levels:channel.title" username={<LinkContainer to={"/user/" + this.props.params.username}><a className="mikuia-page-header-link">{this.state.user.displayName}</a></LinkContainer>} />
									</h1>

									<div className="mikuia-page-card">
										<For each="user" index="i" of={this.state.users}>
											<Card ranking key={user.username}>
												<CardBlock ranking flexBasis={80} title={t('levels:leaderboard.rank')} value={"#" + (i + 1)} />

												<CardBlock flexBasis={300}>
													<CardBlockUser username={user.username} />
												</CardBlock>

												<CardBlock flexBasis={150} alignRight title={t('levels:leaderboard.experience')} value={Tools.commas(user.experience)} />
												<CardBlock flexBasis={50} alignRight title={t('levels:leaderboard.level')}>
													<LevelCircle experience={user.experience} />
												</CardBlock>
												<CardBlock flexBasis={70} alignRight title={t('levels:leaderboard.progress')} value={Tools.getLevelProgress(user.experience) + "%"} />
											</Card>
										</For>
										<If condition={this.state.loading}>
											<Card>
												<CardBlock flexBasis={20}>
													<i className="fa fa-spinner fa-spin" />
												</CardBlock>
											</Card>
										</If>
									</div>

								</Col>
								<Col md={4} className="hidden-xs hidden-sm">
									<Choose>
										<When condition={this.context.auth && this.context.user.username != this.props.params.username && this.state.stats.experience}>
											<h1 className="mikuia-page-header-text text-white">{t('levels:sidebar.yourStats')}</h1>
										</When>
										<Otherwise>
											<h1 className="mikuia-page-header-text text-white">{t('levels:sidebar.tips.title')}</h1>
										</Otherwise>
									</Choose>

									<Authenticated>
										<If condition={this.context.user.username != this.props.params.username && this.state.stats.experience}>
											<div className="mikuia-page-card mikuia-page-card-margin-3x">
												<Card>
													<CardBlock title={t('levels:leaderboard.rank')} value={"#" + Tools.commas(this.state.stats.rank)} />
													<CardBlock title={t('levels:leaderboard.experience')} value={Tools.commas(this.state.stats.experience)} />
													<CardBlock title={t('levels:leaderboard.level')}>
														<LevelCircle experience={this.state.stats.experience} />
													</CardBlock>
													<CardBlock title={t('levels:leaderboard.progress')} value={Tools.getLevelProgress(this.state.stats.experience) + "%"} />
												</Card>
											</div>
											<h1 className="mikuia-page-header-text">{t('levels:sidebar.tips.title')}</h1>
										</If>
									</Authenticated>
									<NotAuthenticated>
										<div className="mikuia-page-card mikuia-page-card-margin">
											<div className="mikuia-page-category-heading">{t('levels:sidebar.tips.outdatedInfo.title')}</div>
											<p>{t('levels:sidebar.tips.outdatedInfo.description')}</p>
										</div>
									</NotAuthenticated>

									<div className="mikuia-page-card mikuia-page-card-special mikuia-page-card-margin">
										<a href="https://patreon.com/hatsuney">
											<h3 className="mikuia-page-category-heading">{t('levels:sidebar.tips.patreon.title')}</h3>
											<p><Interpolate i18nKey='levels:sidebar.tips.patreon.description' useDangerouslySetInnerHTML={true} /></p>
										</a>
									</div>

									<div className="mikuia-page-card mikuia-page-card-margin">
										<div className="mikuia-page-category-heading">{t('levels:sidebar.tips.bots.title')}</div>
										<p>
											{t('levels:sidebar.tips.bots.description')}
											<br />
											<a href="http://discord.mikuia.tv">{t('levels:sidebar.tips.bots.link')}</a>
											<br />
											<small className="text-muted">{t('levels:sidebar.tips.bots.disclaimer')}</small>
										</p>
									</div>

									<div className="mikuia-page-card mikuia-page-card-margin">
										<div className="mikuia-page-category-heading">{t('levels:sidebar.tips.accounts.title')}</div>
										<p>
											{t('levels:sidebar.tips.accounts.description')}
											<br />
											<LinkContainer to="/settings">
												<a>{t('levels:sidebar.tips.accounts.link')}</a>
											</LinkContainer>
										</p>
									</div>

									<div className="mikuia-page-card mikuia-page-card-margin">
										<div className="mikuia-page-category-heading">{t('levels:sidebar.tips.levels.title')}</div>
										<p>{t('levels:sidebar.tips.levels.description')}</p>
										<b>{t('levels:sidebar.tips.levels.descriptionTitle')}</b>
										<ul><Interpolate i18nKey='levels:sidebar.tips.levels.list' useDangerouslySetInnerHTML={true} /></ul>
									</div>

								</Col>
							</Row>
						</div>
					</When>
					<Otherwise>
						<ErrorPage>
							<h3>{t('levels:channel.failure')}</h3>
							<br />
							<p><Interpolate i18nKey='levels:channel.failureDescription' useDangerouslySetInnerHTML={true} /></p>
						</ErrorPage>
					</Otherwise>
				</Choose>
			</Grid>
		)
	}

})

export default translate('levels', {wait: true})(LevelsChannel)