import React, { useCallback, useEffect, useRef, useState } from 'react'
import PropTypes from 'prop-types'
import {
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CForm,
  CFormInput,
  CRow,
  CSpinner,
} from '@coreui/react'

import { changePassword, getCurrentUser, updateCurrentUser } from '../../api/authService'
import { getApiErrorMessage } from '../../api/apiUtils'
import { ErrorAlert, LoadingState, StatusBadge } from '../../components/admin/AdminPageState'
import AdminToast from '../../components/admin/AdminToast'
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

const initialPasswordForm = {
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
}

const Profile = () => {
  const { user, updateUser, logout } = useAuth()
  const fallbackUserRef = useRef(user)
  const [profile, setProfile] = useState(user)
  const [form, setForm] = useState({ fullName: '', phone: '', avatar: '' })
  const [passwordForm, setPasswordForm] = useState(initialPasswordForm)
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(true)
  const [savingProfile, setSavingProfile] = useState(false)
  const [savingPassword, setSavingPassword] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const resetForm = useCallback((nextProfile) => {
    setForm({
      fullName: nextProfile?.fullName || '',
      phone: nextProfile?.phone || '',
      avatar: nextProfile?.avatar || '',
    })
  }, [])

  useEffect(() => {
    fallbackUserRef.current = user
  }, [user])

  const loadProfile = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getCurrentUser()
      setProfile(data)
      updateUser(data)
      resetForm(data)
    } catch (loadError) {
      const fallbackUser = fallbackUserRef.current
      setError(getApiErrorMessage(loadError))
      setProfile(fallbackUser)
      resetForm(fallbackUser)
    } finally {
      setLoading(false)
    }
  }, [resetForm, updateUser])

  useEffect(() => {
    const loadTimer = window.setTimeout(loadProfile, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadProfile])

  const handleProfileSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setSuccess('')

    if (!form.fullName.trim()) {
      setError('Full name is required.')
      return
    }

    setSavingProfile(true)

    try {
      const updated = await updateCurrentUser({
        fullName: form.fullName.trim(),
        phone: form.phone.trim() || null,
        avatar: form.avatar.trim() || null,
      })
      setProfile(updated)
      updateUser(updated)
      resetForm(updated)
      setSuccess('Profile updated.')
    } catch (saveError) {
      setError(getApiErrorMessage(saveError))
    } finally {
      setSavingProfile(false)
    }
  }

  const handlePasswordSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setSuccess('')

    if (!passwordForm.currentPassword || !passwordForm.newPassword) {
      setError('Current password and new password are required.')
      return
    }

    if (passwordForm.newPassword.trim().length < 8) {
      setError('New password must be at least 8 characters.')
      return
    }

    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      setError('Password confirmation does not match.')
      return
    }

    setSavingPassword(true)

    try {
      await changePassword({
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      })
      setPasswordForm(initialPasswordForm)
      logout(true, { authError: 'Password changed. Please sign in again.' })
    } catch (passwordError) {
      setError(getApiErrorMessage(passwordError))
    } finally {
      setSavingPassword(false)
    }
  }

  const handleProfileChange = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  const handlePasswordChange = (field, value) => {
    setPasswordForm((current) => ({ ...current, [field]: value }))
  }

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <strong>Admin Profile</strong>
          <CButton color="secondary" variant="outline" onClick={loadProfile} disabled={loading}>
            Refresh
          </CButton>
        </CCardHeader>
        <CCardBody>
          <ErrorAlert message={error} />

          {loading ? (
            <LoadingState label="Loading profile..." />
          ) : (
            <>
              <CRow className="g-3 mb-4">
                <ProfileField label="Email" value={profile?.email} />
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

              <CForm onSubmit={handleProfileSubmit}>
                <CRow className="g-3">
                  <CCol md={6}>
                    <CFormInput
                      label="Full name"
                      value={form.fullName}
                      maxLength={100}
                      required
                      disabled={savingProfile}
                      onChange={(event) => handleProfileChange('fullName', event.target.value)}
                    />
                  </CCol>
                  <CCol md={6}>
                    <CFormInput
                      label="Phone"
                      value={form.phone}
                      maxLength={20}
                      disabled={savingProfile}
                      onChange={(event) => handleProfileChange('phone', event.target.value)}
                    />
                  </CCol>
                  <CCol xs={12}>
                    <CFormInput
                      label="Avatar URL"
                      value={form.avatar}
                      maxLength={500}
                      disabled={savingProfile}
                      onChange={(event) => handleProfileChange('avatar', event.target.value)}
                    />
                  </CCol>
                  <CCol xs={12} className="d-flex flex-wrap gap-2">
                    <CButton color="primary" type="submit" disabled={savingProfile}>
                      {savingProfile && <CSpinner component="span" size="sm" className="me-2" />}
                      Save profile
                    </CButton>
                    <CButton
                      color="secondary"
                      variant="outline"
                      type="button"
                      disabled={savingProfile}
                      onClick={() => resetForm(profile)}
                    >
                      Cancel
                    </CButton>
                  </CCol>
                </CRow>
              </CForm>
            </>
          )}
        </CCardBody>
      </CCard>

      <CCard className="mb-4">
        <CCardHeader>
          <strong>Change Password</strong>
        </CCardHeader>
        <CCardBody>
          <CForm onSubmit={handlePasswordSubmit}>
            <CRow className="g-3">
              <CCol md={6}>
                <CFormInput
                  type={showPassword ? 'text' : 'password'}
                  label="Current password"
                  autoComplete="current-password"
                  value={passwordForm.currentPassword}
                  disabled={savingPassword}
                  onChange={(event) => handlePasswordChange('currentPassword', event.target.value)}
                />
              </CCol>
              <CCol md={6} className="d-flex align-items-end">
                <CButton
                  type="button"
                  color="secondary"
                  variant="outline"
                  aria-pressed={showPassword}
                  aria-label={showPassword ? 'Hide passwords' : 'Show passwords'}
                  onClick={() => setShowPassword((current) => !current)}
                >
                  {showPassword ? 'Hide passwords' : 'Show passwords'}
                </CButton>
              </CCol>
              <CCol md={6}>
                <CFormInput
                  type={showPassword ? 'text' : 'password'}
                  label="New password"
                  autoComplete="new-password"
                  value={passwordForm.newPassword}
                  disabled={savingPassword}
                  onChange={(event) => handlePasswordChange('newPassword', event.target.value)}
                />
              </CCol>
              <CCol md={6}>
                <CFormInput
                  type={showPassword ? 'text' : 'password'}
                  label="Confirm new password"
                  autoComplete="new-password"
                  value={passwordForm.confirmPassword}
                  disabled={savingPassword}
                  onChange={(event) => handlePasswordChange('confirmPassword', event.target.value)}
                />
              </CCol>
              <CCol xs={12}>
                <CButton color="primary" type="submit" disabled={savingPassword}>
                  {savingPassword && <CSpinner component="span" size="sm" className="me-2" />}
                  Change password
                </CButton>
              </CCol>
            </CRow>
          </CForm>
        </CCardBody>
      </CCard>
    </>
  )
}

export default Profile
