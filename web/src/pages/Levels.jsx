import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {LinkContainer} from 'react-router-bootstrap'
import {Button, Col, Grid, OverlayTrigger, Row, Tooltip} from 'react-bootstrap'
import {translate} from 'react-i18next'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockUser from '../components/community/CardBlockUser'
import LevelCircle from '../components/community/LevelCircle'

import {Authenticated, NotAuthenticated} from '../components/Auth'
import Tools from '../tools'

var Levels = React.createClass({
	contextTypes: {
		auth: React.PropTypes.bool,
		user: React.PropTypes.object
	},

	componentDidMount: function() {
		this.props.setHeaderOption('title', [this.props.t('header:link.levels')])
		this.poll()
	},

	getInitialState: function() {
		return {
			channels: [],
			error: false,
			loading: true,
			stats: {}
		}
	},

	poll: function() {
		var self = this
		self.setState({
			loading: true
		})
		$.get('/api/levels').success(function(data) {
			self.setState({
				channels: data.channels,
				loading: false
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				channels: []
			})
		})
		this.pollStats()
	},

	pollStats: function() {
		var self = this
		if(this.context.auth) {
			$.get('/api/user/' + this.context.user.username + '/stats/levels').success(function(data) {
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
			<div>
				<Grid>
					<Row>
						<Col md={4} mdPush={8}>
							<Authenticated>
								<If condition={this.state.stats}>
									<h1 className="mikuia-page-header-text">
										{t('levels:sidebar.yourStats')}
									</h1>
								</If>

								<If condition={this.state.stats}>
									<Card>
										<CardBlock title={t('levels:global.rank')} value={"#" + Tools.commas(this.state.stats.rank)} />
										<CardBlock title={t('levels:leaderboard.experience')} value={Tools.commas(this.state.stats.experience)} />
										<CardBlock alignRight title={t('levels:global.level')}>
											<LevelCircle experience={this.state.stats.experience} />
										</CardBlock>
									</Card>
									<LinkContainer to={"/user/" + this.context.user.username + "/levels"}><a className="pull-right">{t('common:seeMoreArrows')}</a></LinkContainer>
								</If>
							</Authenticated>
						</Col>
						<Col md={8} mdPull={4}>
							<h1 className="mikuia-page-header-text">
								{t('levels:randomChannels')}

								<div className="pull-right">
									<OverlayTrigger placement="top" overlay={
										<Tooltip id="tooltip-randomize">{t('levels:randomize')}</Tooltip>
									}>
										<Button bsStyle="default" disabled={this.state.loading} onClick={this.poll}><i className={classNames({"fa fa-refresh": true, "fa-spin": this.state.loading})}></i></Button>
									</OverlayTrigger>
								</div>
							</h1>

							<div className={classNames({"mikuia-loading": this.state.loading})}>
								<For each="channel" of={this.state.channels}>
									<Card key={channel.username}>
										<CardBlock flexBasis={300}>
											<CardBlockUser username={channel.username} link={"/levels/" + channel.username} />
										</CardBlock>

										<CardBlock flexBasis={125} alignRight title={t('levels:leaderboard.uniqueViewers')} value={Tools.commas(channel.users)} />
										<CardBlock flexBasis={125} alignRight title={t('levels:leaderboard.yourRank')} value="-" />
										<CardBlock flexBasis={125} alignRight title={t('levels:leaderboard.yourLevel')} value="-" />
										<CardBlock flexBasis={125} alignRight title={t('levels:leaderboard.progress')} value="-" />

									</Card>
								</For>
							</div>
							<If condition={this.state.channels.length == 0}>
								<span className="text-muted"><i className="fa fa-spinner fa-spin"></i> {t('common:loading3dots')}</span>
							</If>
						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('levels', {wait: true})(Levels)