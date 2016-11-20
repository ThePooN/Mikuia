import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Col, Grid, Row} from 'react-bootstrap'
import {translate, Interpolate} from 'react-i18next'
import {LinkContainer} from 'react-router-bootstrap'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockSource from '../components/community/CardBlockSource'
import CardBlockUser from '../components/community/CardBlockUser'
import LevelCircle from '../components/community/LevelCircle'
import ErrorPage from '../components/community/ErrorPage'

import Tools from '../tools'

var UserLevels = React.createClass({

	addLevels: function(offset) {
		var shownLevels = this.state.shownLevels.slice(0)
		var endOffset = Math.min(offset + 30, this.state.levels.length)
		for(var i = offset; i < endOffset; i++) {
			shownLevels.push(this.state.levels[i])
		}
		this.setState({
			loading: false,
			shownLevels: shownLevels,
			offset: endOffset
		})
	},

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('splash', false)
			self.props.setHeaderOption('title', [self.props.t('header:user.profile'), self.state.user.displayName, 'Levels'])
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
			levels: [],
			shownLevels: [],
			user: {
				displayName: this.props.params.username,
				logo: ''
			},
			offset: 0,
			error: false,
			loading: true,
			stats: {}
		}
	},

	loadLevels: function(offset) {
		var self = this
		var levels = self.state.levels
		if(levels.length == 0) {
			$.get('/api/user/' + this.props.params.username + '/levels').success(function(data) {
				for(var userId in data.levels) {
					levels.push(data.levels[userId])
				}

				self.setState({
					levels: levels,
					offset: 0,
					loading: false
				}, function() {
					self.addLevels(0)
				})

			}).fail(function() {
				self.setState({
					error: true,
					loading: false,
					levels: levels
				})
			})
		} else {
			self.addLevels(this.state.offset)
		}
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
			self.props.setHeaderOption('title', [self.props.t('header:user.profile'), self.state.user.displayName, self.props.t('header:link.levels')])

		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				user: {}
			})
		})

		this.loadLevels(0)
		this.pollStats()
	},

	pollStats: function() {
		var self = this
		$.get('/api/user/' + this.props.params.username + '/stats/levels').success(function(data) {
			self.setState({
				stats: data
			})
		})
	},

	render: function() {
		const {t} = this.props
		return (
			<Grid>
				<Choose>
					<When condition={!this.state.error}>
						<div className="mikuia-page-padding">
							<Row>
								<Col md={4} mdPush={8}>
									<h1 className="mikuia-page-header-text text-white">
										{t('levels:global.stats')}
									</h1>

									<div className="mikuia-page-card">
										<If condition={this.state.stats}>
											<Card>
												<CardBlock title={t('levels:global.rank')} value={"#" + Tools.commas(this.state.stats.rank)} />
												<CardBlock title={t('levels:leaderboard.experience')} value={Tools.commas(this.state.stats.experience)} />
												<CardBlock alignRight title={t('levels:global.level')}>
													<LevelCircle experience={this.state.stats.experience} />
												</CardBlock>
											</Card>
										</If>
									</div>
								</Col>
								<Col md={8} mdPull={4}>
									<h1 className="mikuia-page-header-text text-white">
										<Interpolate i18nKey='levels:user.title' username={<LinkContainer to={"/user/" + this.props.params.username}><a className="mikuia-page-header-link">{this.state.user.displayName}</a></LinkContainer>} />
									</h1>

									<div className="mikuia-page-card">
										<For each="user" index="i" of={this.state.shownLevels}>
											<Card ranking key={user.username}>
												<CardBlock flexBasis={250}>
													<CardBlockUser username={user.username} link={"/levels/" + user.username} />
												</CardBlock>

												<CardBlock flexBasis={150} alignRight title={t('levels:leaderboard.experience')} value={Tools.commas(user.experience)} />
												<CardBlockSource flexBasis={150} alignRight title={t('levels:leaderboard.rank')} url={"/api/user/" + this.props.params.username + "/levels/" + user.username} value="rank" prefix="#" link={"/levels/" + user.username}/>
												<CardBlock flexBasis={70} alignRight title={t('levels:leaderboard.level')}>
													<LevelCircle experience={user.experience} />
												</CardBlock>
												<CardBlock flexBasis={100} alignRight title={t('levels:leaderboard.progress')} value={Tools.getLevelProgress(user.experience) + "%"} />
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
							</Row>
						</div>
					</When>
					<Otherwise>
						<ErrorPage>
							<h3>{t('levels:user.failure')}</h3>
							<br />
							<p><Interpolate i18nKey='levels:user.failureDescription' useDangerouslySetInnerHTML={true} /></p>
						</ErrorPage>
					</Otherwise>
				</Choose>
			</Grid>
		)
	}

})

export default translate('levels', {wait: true})(UserLevels)