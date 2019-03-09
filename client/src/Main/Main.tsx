import React, { Component } from 'react'
import axios from 'axios'
import { Nav, Dropdown, Col, Row } from "react-bootstrap";

class Main extends Component {
  state = {
    data: { rows:[{userid:0 , name:'', address:''}] },
    user: null,
    tab: "Items",
  }

  async componentDidMount() {
    const payload = (await axios.post(`http://localhost:5000/stuffshare/users`)).data
    console.log(payload)

    this.setState({
      ...payload,
    })
  }

  changeUser = (user: string) => {
    this.setState({user})
  } 

  changeTab = (tab: string) => {
    this.setState({tab})
  }

  render() {
    const { data } = this.state
    let content = <div>Item name</div>
    // if (data === null) return <p>Loading ...</p>
    let dropdownMenu:any[] = []

    data.rows.forEach(row => {
      let name = row.name;
      dropdownMenu.push(
        <Dropdown.Item onSelect={() => this.changeUser(name)}>{name}</Dropdown.Item>
      )
    });

    return (
      // <div className="container">
      //   <div className="row">
      //     <div className="jumbotron col-12 text-center">
      //       <h1 className="display-3">{data.title}</h1>
      //       <p className="lead">{data.description}</p>
      //     </div>
      //   </div>
      // </div>
      <div className="container">
        <Row>
          <Col md="auto">
          <Dropdown>
            <Dropdown.Toggle variant="primary" id="dropdown-basic">
              Select User
            </Dropdown.Toggle>
            <Dropdown.Menu>
              {dropdownMenu}
            </Dropdown.Menu>
          </Dropdown>
          </Col>
          <Col>
          <h4 className="user">
  	        {this.state.user}
          </h4>
          </Col>
        </Row>
        <Nav variant="tabs" activeKey={this.state.tab}>
          <Nav.Item>
            <Nav.Link eventKey="Items" onSelect={() => this.changeTab("Items")}>Items</Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey="Loans" onSelect={() => this.changeTab("Loans")}>Loans</Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey="Other Users" onSelect={() => this.changeTab("Other Users")}>Other Users</Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey="Past Loans" onSelect={() => this.changeTab("Past Loans")}>Past Loans</Nav.Link>
          </Nav.Item>
        </Nav>
        {content}
      </div>
    )
  }
}

export default Main
