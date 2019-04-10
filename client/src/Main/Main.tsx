import React, { Component, useReducer } from 'react'
import * as _ from 'lodash'
import axios from 'axios'
import {
  Nav,
  Dropdown,
  Col,
  Row,
  Card,
  Container,
  CardDeck,
  Spinner,
  Button,
  OverlayTrigger,
  Popover,
} from 'react-bootstrap'
import * as Icon from 'react-feather'

import AddItem from '../Components/AddItem'
import NavBar from '../Components/NavBar'
import UserInterestGroups from '../Components/UserInterestGroups'
import UserEvents from '../Components/UserEvents'
import InterestGroups from '../InterestGroups/InterestGroups'
import Adverisements from '../Components/Advertisements';
import ComplexQueries from '../Components/ComplexQueries';

class Main extends Component {
  state = {
    data: {},
    userList: [],
    selectedUser: {},
    selectedTab: '',
    userItems: [],
    content: [],
    isLoading: false,
    pageToRender: 'Profile',
    advertisements: [],
    items: [],
  }

  async componentDidMount() {
    let payload = (await axios.get(`/users`)).data

    this.setState(
      {
        ...payload,
      },
      () => this.loadUsers(),
    )
    payload = (await axios.get('/advertisements')).data
    this.setState({advertisements: payload.data.rows})
    console.log(payload.data.rows)
    payload = (await axios.get('/items')).data
    this.setState({items: payload.data.rows})
  }

  toggleLoading = (callback: () => void) => {
    this.setState({ isLoading: !this.state.isLoading }, callback)
  }

  changeUser = (name: string, userId: number) => {
    this.setState({ selectedUser: { name, userId } }, async () => {
      await this.loadTabData()
    })
  }

  loadUsers = () => {
    const { data } = this.state

    let userList: any[] = []
    _.get(data, 'rows').forEach((row: any) => {
      let name = row.name
      let userid = row.userid
      userList.push(
        <Dropdown.Item onSelect={() => this.changeUser(name, userid)}>
          {name}
        </Dropdown.Item>,
      )
    })
    this.setState({ userList })
  }

  updateTab = () => {
    const { userItems, selectedTab, selectedUser } = this.state
    let content: any[] = []

    switch (selectedTab) {
      case 'AddItem':
        content.push(
          <AddItem
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
            loadTabData={this.loadTabData}
            isEditing={false}
          />,
        )
        break
      case 'Items':
        userItems.forEach((row) => {
          const popover = (
            <Popover
              id="popover-basic"
              title="Edit Item"
              style={{ width: '18rem' }}
            >
              <AddItem
                selectedUser={selectedUser}
                toggleLoading={this.toggleLoading}
                loadTabData={this.loadTabData}
                selectedItem={row}
                isEditing={true}
              />
            </Popover>
          )

          content.push(
            <CardDeck style={{ paddingBottom: '10px' }}>
              <Card
                className="text-center"
                bg="dark"
                text="white"
                border="dark"
                style={{ width: '18rem' }}
              >
                <Card.Body>
                  <Card.Title>
                    {_.get(row, 'itemname')}{' '}
                    <OverlayTrigger
                      rootClose={true}
                      trigger="click"
                      placement="right"
                      overlay={popover}
                    >
                      <Icon.Edit style={{ cursor: 'pointer' }} />
                    </OverlayTrigger>
                  </Card.Title>
                  <Card.Subtitle>Price: ${_.get(row, 'value')}</Card.Subtitle>
                  <Card.Text>
                    Description: {_.get(row, 'itemdescription')}
                  </Card.Text>
                </Card.Body>
                <Card.Footer>
                  <div>
                    <Button variant="light" size="sm">
                      Put Up For Loan
                    </Button>
                  </div>
                </Card.Footer>
              </Card>
            </CardDeck>,
          )
        })
        break
      case 'Loans':
        // content = <div>Loan name</div>
        break
      case 'Interest Groups':
        content.push(
          <UserInterestGroups
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
          />,
        )
        break
      case 'Advertisements':
        content.push(<Adverisements 
          loadTabData={this.loadTabData}
          currentUser={this.state.selectedUser}
          userList={this.state.userList} 
          items={this.state.items} 
          advertisements={this.state.advertisements}/>)
        break
      case 'Complex Queries':
        content.push(<ComplexQueries/>)
        break
      case 'Events':
        content.push(
          <UserEvents
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
          />,
        )
      default:
        break
    }

    this.setState({ content })
  }

  renderWelcomeMessage = () => (
    <CardDeck style={{ paddingBottom: '10px' }}>
      <Card
        className="text-center"
        bg="dark"
        text="white"
        border="dark"
        style={{ width: '18rem' }}
      >
        <Card.Body>
          <Card.Title>Welcome to CarouShare!</Card.Title>
        </Card.Body>
      </Card>
    </CardDeck>
  )

  loadTabData = async () => {
    const { selectedUser } = this.state
    const userId = _.get(selectedUser, 'userId')

    const items = await axios.post(`/users/items`, {
      userId,
    })
    const ads = (await axios.get('/advertisements')).data
    this.setState({advertisements: ads.data.rows}, ()=>{
      this.updateTab()
    })
    this.setState({ userItems: items.data.data.rows }, () => {
      this.updateTab()
    })
  }

  changeTab = (selectedTab: string) => {
    this.setState({ selectedTab }, this.loadTabData)
  }

  renderPage = (page: string) => {
    const { selectedTab, selectedUser, content } = this.state
    switch (page) {
      case 'Profile':
        return (
          <Container>
            <Row>
              <Col>
                <Nav
                  className="justify-content-center"
                  variant="pills"
                  activeKey={selectedTab}
                  style={{ height: '50px' }}
                >
                  <Nav.Item>
                    <Nav.Link
                      eventKey="AddItem"
                      onSelect={() => this.changeTab('AddItem')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Add Item
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Items"
                      onSelect={() => this.changeTab('Items')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Your Items
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Loans"
                      onSelect={() => this.changeTab('Loans')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Loans
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Interest Groups"
                      onSelect={() => this.changeTab('Interest Groups')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Your Groups
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Advertisements"
                      onSelect={() => this.changeTab('Advertisements')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Advertisements
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Complex Queries"
                      onSelect={() => this.changeTab('Complex Queries')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Complex Queries
                    </Nav.Link> 
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link>
                      eventKey="Events"
                      onSelect={() => this.changeTab('Events')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Events
                    </Nav.Link>
                  </Nav.Item>
                </Nav>
              </Col>
            </Row>
            <Row style={{ paddingBottom: '20px' }}>
              <Col>
                {_.isEmpty(selectedTab) ? this.renderWelcomeMessage() : content}
              </Col>
            </Row>
          </Container>
        )
      case 'Interest Groups':
        return (
          <InterestGroups
            selectedUser={this.state.selectedUser}
            toggleLoading={this.toggleLoading}
          />
        )
      default:
        return
    }
  }

  changePage = (page: string) => {
    this.setState({ pageToRender: page })
  }

  render() {
    const {
      selectedTab,
      selectedUser,
      userList,
      content,
      isLoading,
      pageToRender,
    } = this.state

    return (
      <>
        <NavBar
          selectedUser={selectedUser}
          userList={userList}
          changePage={this.changePage}
        />
        {isLoading ? (
          <div style={{ textAlign: 'center' }}>
            <Spinner animation="border" role="status" />
          </div>
        ) : (
          this.renderPage(pageToRender)
        )}
      </>
    )
  }
}

export default Main
