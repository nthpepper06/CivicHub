import React, { useCallback, useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { CAlert, CBadge, CButton, CCard, CCardBody, CCardHeader, CCol, CRow } from '@coreui/react'

import { getCurrentUser } from '../../api/authService'
import { getApiErrorMessage } from '../../api/apiUtils'
import { ErrorAlert, LoadingState, StatusBadge } from '../../components/admin/AdminPageState'
import useAuth from '../../hooks/useAuth'
import { booleanStatusColor, formatLabel } from '../../utils/display'

const ProfileField = ({ label, value }) => (
  <CCol md={6} xl={4}>
    <div className="small text-body-secondary">{label}</div>
    <div className="fw-semibold text-break">{value || '-'}</div>
  </CCol>
)

ProfileField.propTypes = {
  label: PropTypes.string.isRequired,
  value: PropTypes.node,
}

const Profile = () => {
  const { user } = useAuth()
  const [profile, setProfile] = useState(user)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const loadProfile = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      setProfile(await getCurrentUser())
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
      setProfile(user)
    } finally {
      setLoading(false)
    }
  }, [user])

  useEffect(() => {
    const loadTimer = window.setTimeout(loadProfile, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadProfile])

  return (
    <CCard className="mb-4">
      <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
        <strong>Admin Profile</strong>
        <CButton color="secondary" variant="outline" onClick={loadProfile} disabled={loading}>
          Refresh
        </CButton>
      </CCardHeader>
      <CCardBody>
        <ErrorAlert message={error} />
        <CAlert color="info">
          Profile editing and password changes are read-only in this admin because the backend only
          exposes the current-user profile endpoint.
        </CAlert>

        {loading ? (
          <LoadingState label="Loading profile..." />
        ) : (
          <CRow className="g-3">
            <ProfileField label="Full name" value={profile?.fullName} />
            <ProfileField label="Email" value={profile?.email} />
            <ProfileField label="Phone" value={profile?.phone} />
            <CCol md={6} xl={4}>
              <div className="small text-body-secondary">Role</div>
              <CBadge color="primary">{formatLabel(profile?.role)}</CBadge>
            </CCol>
            <CCol md={6} xl={4}>
              <div className="small text-body-secondary">Account status</div>
              <StatusBadge value={profile?.status} />
            </CCol>
            <CCol md={6} xl={4}>
              <div className="small text-body-secondary">Active</div>
              <CBadge color={booleanStatusColor(profile?.isActive)}>
                {profile?.isActive ? 'Active' : 'Inactive'}
              </CBadge>
            </CCol>
            <ProfileField label="Department" value={profile?.departmentName} />
          </CRow>
        )}
      </CCardBody>
    </CCard>
  )
}

export default Profile
