import React from 'react'
import {
  CDropdown,
  CDropdownHeader,
  CDropdownItem,
  CDropdownMenu,
  CDropdownToggle,
} from '@coreui/react'
import { cilAccountLogout, cilUser } from '@coreui/icons'
import CIcon from '@coreui/icons-react'

import useAuth from '../../hooks/useAuth'

const AppHeaderDropdown = () => {
  const { user, logout } = useAuth()

  return (
    <CDropdown variant="nav-item">
      <CDropdownToggle placement="bottom-end" className="py-0 pe-0 d-flex align-items-center">
        <div className="text-end me-2 d-none d-sm-block">
          <div className="fw-semibold">{user?.fullName || user?.email || 'Admin'}</div>
          <small className="text-body-secondary">{user?.role || 'ADMIN'}</small>
        </div>
        <CIcon icon={cilUser} size="lg" />
      </CDropdownToggle>
      <CDropdownMenu className="pt-0" placement="bottom-end">
        <CDropdownHeader className="bg-body-secondary fw-semibold mb-2">
          CivicHub Admin
        </CDropdownHeader>
        <CDropdownItem as="button" type="button" onClick={() => logout()}>
          <CIcon icon={cilAccountLogout} className="me-2" />
          Logout
        </CDropdownItem>
      </CDropdownMenu>
    </CDropdown>
  )
}

export default AppHeaderDropdown
