import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

var UserBadge = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			user: {
				displayName: this.props.username,
				logo: ''
			}
		}
	},

	poll: function() {
		var self = this
		$.get('/api/user/' + this.props.username).success(function(data) {
			self.setState({
				user: data.user
			})
		}).fail(function() {
			self.setState({
				error: true,
				user: {}
			})
		})
	},

	render: function() {
		return (
			<LinkContainer to={'/user/' + this.props.username}>
				<a>
					<img className="img-circle" src={this.state.user.logo} width="16" height="16" /> {this.state.user.displayName}
				</a>
			</LinkContainer>
		)
	}

})

export default UserBadge