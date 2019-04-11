import React, { Component } from 'react'
import { Table } from 'react-bootstrap'
import axios from 'axios';

class ComplexQueries extends Component<{items: any[], userList: any[]},{bigFan: any[], enemy: any[], popular: any[]}> {
	constructor(props: any) {
		super(props)
		this.state = {
			bigFan: [],
			enemy: [],
			popular: [],
		}
		this.getComplexQueries()
	}
	getComplexQueries = async () => {
		const bigFan = (await axios.get('/bigfan')).data.data.rows
		const enemy = (await axios.get('/enemy')).data.data.rows
		const popular = (await axios.get('/popular')).data.data.rows
		console.log(popular)
		this.setState({bigFan, enemy, popular})
	}
	render() {
		const { bigFan, enemy, popular } = this.state
		const { userList, items } = this.props
		let table1:any[] = []
		bigFan.forEach(user => {
			const username = userList[user.loanerid - 1].props.children
			const fanName = userList[user.fan - 1].props.children
			table1.push(
				<tr>
					<td>{user.loanerid}</td>
					<td>{username}</td>
					<td>{user.fan}</td>
					<td>{fanName}</td>
				</tr>
			)
		})
		let table2:any[] = []
		enemy.forEach(user => {
			const username = userList[user.hated - 1].props.children
			const fanName = userList[user.hater - 1].props.children
			table2.push(
				<tr>
					<td>{user.hated}</td>
					<td>{username}</td>
					<td>{user.hater}</td>
					<td>{fanName}</td>
				</tr>
			)
		})
		let table3:any[] = []
		popular.forEach(list => {
			console.log(items)
			const first = items[list.mostpopularitem - 1]
			const second = items[list.secondmostpopularitem - 1]
			const third = items[list.thirdmostpopularitem - 1]
			table3.push(
				<tr>
					<td>{list.year}</td>
					<td>{list.month}</td>
					<td>{first == null ? "Nil" : first.itemname}</td>
					<td>{second == null ? "Nil" : second.itemname}</td>
					<td>{third == null ? "Nil" : third.itemname}</td>
				</tr>
			)
		})
		return(<div>
			<Table striped bordered>
				<thead>
					<tr>
						<th>Current User Id</th>
						<th>Current User</th>
						<th>Fan Id</th>
						<th>Fan</th>
					</tr>
				</thead>
				<tbody>
					{table1}
				</tbody>
			</Table>
			<Table striped bordered>
				<thead>
					<tr>
						<th>Current User Id</th>
						<th>Current User</th>
						<th>Enemy Id</th>
						<th>Enemy</th>
					</tr>
				</thead>
				<tbody>
					{table2}
				</tbody>
			</Table>
			<Table striped bordered>
				<thead>
					<tr>
						<th>Year</th>
						<th>Month</th>
						<th>Most Popular Item</th>
						<th>2nd Most Popular Item</th>
						<th>3rd Most Popular Item</th>
					</tr>
				</thead>
				<tbody>
					{table3}
				</tbody>
			</Table>
		</div>)
	}
}
export default ComplexQueries