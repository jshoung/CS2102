import React, { Component } from 'react'
import axios from 'axios'
import { Nav, Dropdown, Col, Row, Card, CardGroup } from 'react-bootstrap'

class Main extends Component {
  state = {
    data: { rows: [{ userid: 0, name: '', address: '' }] },
    user: {name:'', userid: 0},
    tab: '',
    userItems: [{itemid: 0, value: 0}]
  }

  async componentDidMount() {
    const payload = (await axios.post(`http://localhost:5000/users`)).data
    console.log(payload)

    this.setState({
      ...payload,
    })
  }

  changeUser = (name: string, userid: number) => {
    axios.post(`http://localhost:5000/users/items`, {
      userId: userid
    }).then(items => {
      console.log(items)
      this.setState({userItems: items.data.data.rows})
    })
    this.setState({ user: {name, userid} })
  }

  changeTab = (tab: string) => {
    this.setState({ tab })
  }

  render() {
    const { data, tab, user, userItems } = this.state
    let content = null;
    
    switch (tab) {
      case 'Items':
        let innerContent: any[] = []
        userItems.forEach(row => {
          innerContent.push(
            <Card>
              <Card.Body>
                <Card.Title>{row.itemid}</Card.Title>
                <Card.Subtitle>Price: {row.value}</Card.Subtitle>
              </Card.Body>
            </Card>)
        })
        content = <CardGroup>{innerContent}</CardGroup>
        break;
      case 'Loans':
        content = <div>Loan name</div>;
        break;
      case 'Other Users':
        content = <div>Other users</div>;
        break;
      case 'Past Loans':
        content = <div>Past Loan name</div>;
        break;
      default:
        break;
    }

    let dropdownMenu: any[] = []
    data.rows.forEach(row => {
      let name = row.name
      let userid = row.userid
      dropdownMenu.push(
        <Dropdown.Item onSelect={() => this.changeUser(name, userid)}>
          {name}
        </Dropdown.Item>,
      )
    })

    return (
      // <div className='container'>
      //   <div className='row'>
      //     <div className='jumbotron col-12 text-center'>
      //       <h1 className='display-3'>{data.title}</h1>
      //       <p className='lead'>{data.description}</p>
      //     </div>
      //   </div>
      // </div>
      <div className='container'>
        <Row>
          <Col md='auto'>
            <Dropdown>
              <Dropdown.Toggle variant='primary' id='dropdown-basic'>
                Select User
              </Dropdown.Toggle>
              <Dropdown.Menu>{dropdownMenu}</Dropdown.Menu>
            </Dropdown>
          </Col>
          <Col>
            <h4 className='user'>{user.name}</h4>
          </Col>
        </Row>
        <Nav variant='tabs' activeKey={tab}>
          <Nav.Item>
            <Nav.Link eventKey='Items' onSelect={() => this.changeTab('Items')}>
              Items
            </Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey='Loans' onSelect={() => this.changeTab('Loans')}>
              Loans
            </Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link
              eventKey='Other Users'
              onSelect={() => this.changeTab('Other Users')}
            >
              Other Users
            </Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link
              eventKey='Past Loans'
              onSelect={() => this.changeTab('Past Loans')}
            >
              Past Loans
            </Nav.Link>
          </Nav.Item>
        </Nav>
        {content}
      </div>
    )
  }
}

export default Main
