import React from 'react'
import * as _ from 'lodash'
import { Link } from 'react-router-dom'
import * as Icon from 'react-feather'
import { Dropdown } from 'react-bootstrap'

interface OwnProps {
  selectedUser: object
  userDropdownList: object
  changePage: Function
}

const NavBar = (props: OwnProps) => {
  const { selectedUser, userDropdownList, changePage } = props

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary fixed-top">
      <Link
        className="navbar-brand"
        onClick={() => changePage('Profile')}
        to="/"
      >
        <Icon.Link />
        {' CarouShare'}
      </Link>
      <div className="collapse navbar-collapse" id="navbarColor01">
        <ul className="navbar-nav mr-auto">
          <li className="nav-item">
            <Link
              className="nav-link"
              onClick={() => changePage('Browse Items')}
              to="/"
            >
              {'Browse Items'}
            </Link>
          </li>
          <li className="nav-item">
            <Link
              className="nav-link"
              onClick={() => changePage('Interest Groups')}
              to="/"
            >
              {'Interest Groups'}
            </Link>
          </li>
        </ul>
      </div>
      <Dropdown className="my-2 my-lg-0">
        <Dropdown.Toggle
          style={{ width: '300px', fontSize: '24px' }}
          variant="primary"
          id="dropdown-basic"
        >
          {_.get(selectedUser, 'name') || 'Select User'}
        </Dropdown.Toggle>
        <Dropdown.Menu
          style={{
            overflowY: 'scroll',
            width: '300px',
            maxHeight: '500px',
          }}
        >
          {userDropdownList}
        </Dropdown.Menu>
      </Dropdown>
    </nav>
  )
}

export default NavBar
