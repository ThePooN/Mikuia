import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Col, Grid, Row} from 'react-bootstrap'
import {translate, Interpolate} from 'react-i18next'
import {LinkContainer} from 'react-router-bootstrap'
import Timeago from 'react-timeago'

import ErrorPage from '../components/community/ErrorPage'
import UserBadge from '../components/community/UserBadge'

import Tools from '../tools'

var UserLevelHistory = React.createClass({

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('splash', false)
			self.props.setHeaderOption('title', [self.props.t('header:user.profile'), self.state.user.displayName, 'Level History'])
		})

		this.poll()

		$(window).scroll(function() {
			if($('body').height() <= ($(window).height() + $(window).scrollTop())) {
				if(!self.state.loading) {
					self.setState({
						loading: true
					})
					self.loadHistory(self.state.offset)
				}
			}
		})
	},

	getInitialState: function() {
		return {
			history: [],
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

	loadHistory: function(offset) {
		var self = this
		var history = self.state.history
		$.get('/api/user/' + this.props.params.username + '/stats/levels/history?limit=50&offset=' + offset).success(function(data) {
			for(var historyId in data.history) {
				history.push(data.history[historyId])
			}

			self.setState({
				history: history,
				offset: self.state.offset + 50,
				loading: false
			})

		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				loading: false
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
			self.props.setHeaderOption('title', [self.props.t('header:user.profile'), self.state.user.displayName, self.props.t('levels:history.link')])

		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				user: {}
			})
		})

		this.loadHistory(0)
	},

	render: function() {
		const {t} = this.props
		return (
			<Grid>
				<Choose>
					<When condition={!this.state.error}>
						<div className="mikuia-page-padding">
							<Row>
								<Col md={12}>
									<h1 className="mikuia-page-header-text text-white">
										<Interpolate i18nKey='levels:history.title' username={<LinkContainer to={"/user/" + this.props.params.username}><a className="mikuia-page-header-link">{this.state.user.displayName}</a></LinkContainer>} />
									</h1>
								</Col>
							</Row>

							<Row>
								<Col md={12} className="mikuia-page-card">
									<For each="entry" of={this.state.history}>
										<Row>
											<Col xs={3}>
												<b><Timeago date={entry.timestamp * 1000} /></b>
											</Col>
											<Col xs={9}>
												You have earned {entry.experience} XP on <UserBadge username={entry.channel} />'s channel.
											</Col>
										</Row>
									</For>
								</Col>
							</Row>
						</div>
					</When>
					<Otherwise>
						<ErrorPage>
							<h3>{t('levels:history.failure')}</h3>
							<br />
							<p><Interpolate i18nKey='levels:history.failureDescription' useDangerouslySetInnerHTML={true} /></p>
						</ErrorPage>
					</Otherwise>
				</Choose>
			</Grid>
		)
	}

})

export default translate('levels', {wait: true})(UserLevelHistory)