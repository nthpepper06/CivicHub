import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { Navigate, useLocation } from 'react-router-dom'
import { CSpinner } from '@coreui/react'

import useAuth from '../hooks/useAuth'

const ProtectedRoute = ({ children }) => {
  const location = useLocation()
  const { isAuthenticated, isAdmin, logout, restored } = useAuth()

  useEffect(() => {
    if (restored && isAuthenticated && !isAdmin) {
      logout(true, { authError: 'Admin access required.' })
    }
  }, [isAdmin, isAuthenticated, logout, restored])

  if (!restored) {
    return (
      <div className="min-vh-100 d-flex align-items-center justify-content-center">
        <CSpinner color="primary" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (!isAdmin) {
    return null
  }

  return children
}

ProtectedRoute.propTypes = {
  children: PropTypes.node.isRequired,
}

export default ProtectedRoute
