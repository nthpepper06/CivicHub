import React, { useCallback, useEffect, useMemo, useState } from 'react'
import {
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CFormSelect,
  CInputGroup,
  CFormInput,
  CModal,
  CModalBody,
  CModalFooter,
  CModalHeader,
  CModalTitle,
  CRow,
  CSpinner,
  CTable,
  CTableBody,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
} from '@coreui/react'
import CIcon from '@coreui/icons-react'
import { cilInfo, cilSearch } from '@coreui/icons'

import { getDepartments } from '../../api/departmentService'
import {
  assignUserDepartment,
  exportUsers,
  getUser,
  getUsers,
  updateUserStatus,
} from '../../api/userService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  ConfirmDialog,
  EmptyState,
  ErrorAlert,
  LoadingState,
  PagePagination,
  StatusBadge,
} from '../../components/admin/AdminPageState'
import AdminToast from '../../components/admin/AdminToast'
import useAuth from '../../hooks/useAuth'
import useDebouncedValue from '../../hooks/useDebouncedValue'
import { booleanStatusColor, formatDateTime, formatLabel } from '../../utils/display'

const roles = ['ADMIN', 'STAFF', 'CITIZEN']
const statuses = ['ACTIVE', 'INACTIVE', 'BLOCKED']

const Users = () => {
  const { user: currentUser } = useAuth()
  const [users, setUsers] = useState([])
  const [departments, setDepartments] = useState([])
  const [pageInfo, setPageInfo] = useState({ page: 0, totalPages: 0, totalElements: 0 })
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [role, setRole] = useState('')
  const [status, setStatus] = useState('')
  const [isActive, setIsActive] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [direction, setDirection] = useState('DESC')
  const [loading, setLoading] = useState(true)
  const [detailLoading, setDetailLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [detail, setDetail] = useState(null)
  const [assignDepartmentId, setAssignDepartmentId] = useState('')
  const [confirmTarget, setConfirmTarget] = useState(null)
  const debouncedSearch = useDebouncedValue(search, 400)
  const isCurrentUser = (id) => Number(currentUser?.id) === Number(id)

  const queryParams = useMemo(
    () => ({
      page,
      size: 10,
      search: debouncedSearch.trim(),
      role,
      status,
      isActive,
      departmentId,
      sortBy: 'createdAt',
      direction,
    }),
    [debouncedSearch, departmentId, direction, isActive, page, role, status],
  )

  const loadUsers = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getUsers(queryParams)
      setUsers(data.content)
      setPageInfo(data)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [queryParams])

  useEffect(() => {
    const loadTimer = window.setTimeout(loadUsers, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadUsers])

  useEffect(() => {
    const loadDepartments = async () => {
      try {
        const data = await getDepartments({ page: 0, size: 100, isActive: true })
        setDepartments(data.content)
      } catch {
        setDepartments([])
      }
    }

    loadDepartments()
  }, [])

  const openDetail = async (id) => {
    setDetailLoading(true)
    setError('')

    try {
      const data = await getUser(id)
      setDetail(data)
      setAssignDepartmentId(data?.departmentId || '')
    } catch (detailError) {
      setError(getApiErrorMessage(detailError))
    } finally {
      setDetailLoading(false)
    }
  }

  const handleStatusUpdate = async () => {
    if (!confirmTarget) {
      return
    }

    setSaving(true)
    setError('')
    setSuccess('')

    try {
      const updated = await updateUserStatus(confirmTarget.id, confirmTarget.nextActive)
      setSuccess(
        `${updated.fullName || updated.email || `User #${updated.id}`} ${
          updated.isActive ? 'activated' : 'deactivated'
        }.`,
      )
      setConfirmTarget(null)
      if (detail?.id === updated.id) {
        setDetail(updated)
      }
      await loadUsers()
    } catch (statusError) {
      setError(getApiErrorMessage(statusError))
    } finally {
      setSaving(false)
    }
  }

  const handleDepartmentAssign = async () => {
    if (!detail || !assignDepartmentId) {
      return
    }

    setSaving(true)
    setError('')
    setSuccess('')

    try {
      const updated = await assignUserDepartment(detail.id, Number(assignDepartmentId))
      setDetail(updated)
      setAssignDepartmentId(updated.departmentId || '')
      setSuccess('User department updated.')
      await loadUsers()
    } catch (assignError) {
      setError(getApiErrorMessage(assignError))
    } finally {
      setSaving(false)
    }
  }

  const handleExport = async () => {
    setExporting(true)
    setError('')

    try {
      await exportUsers({ ...queryParams, page: undefined, size: undefined })
      setSuccess('Users CSV downloaded.')
    } catch (exportError) {
      setError(getApiErrorMessage(exportError))
    } finally {
      setExporting(false)
    }
  }

  const clearFilters = () => {
    setPage(0)
    setSearch('')
    setRole('')
    setStatus('')
    setIsActive('')
    setDepartmentId('')
    setDirection('DESC')
  }

  const selectedSameDepartment =
    detail?.departmentId && Number(assignDepartmentId) === Number(detail.departmentId)

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <strong>Users</strong>
          <div className="d-flex flex-wrap gap-2">
            <CButton
              color="secondary"
              variant="outline"
              onClick={handleExport}
              disabled={exporting || loading}
            >
              {exporting && <CSpinner component="span" size="sm" className="me-2" />}
              Export CSV
            </CButton>
            <CButton color="secondary" variant="outline" onClick={clearFilters}>
              Clear filters
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <ErrorAlert message={error} />

          <CRow className="g-2 mb-3">
            <CCol md={4}>
              <CInputGroup>
                <span className="input-group-text">
                  <CIcon icon={cilSearch} />
                </span>
                <CFormInput
                  placeholder="Search users"
                  aria-label="Search users"
                  value={search}
                  onChange={(event) => {
                    setPage(0)
                    setSearch(event.target.value)
                  }}
                />
              </CInputGroup>
            </CCol>
            <CCol md={2}>
              <CFormSelect
                value={role}
                aria-label="Filter users by role"
                onChange={(event) => {
                  setPage(0)
                  setRole(event.target.value)
                }}
              >
                <option value="">All roles</option>
                {roles.map((item) => (
                  <option key={item} value={item}>
                    {formatLabel(item)}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={2}>
              <CFormSelect
                value={status}
                aria-label="Filter users by status"
                onChange={(event) => {
                  setPage(0)
                  setStatus(event.target.value)
                }}
              >
                <option value="">All statuses</option>
                {statuses.map((item) => (
                  <option key={item} value={item}>
                    {formatLabel(item)}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={2}>
              <CFormSelect
                value={isActive}
                aria-label="Filter users by active state"
                onChange={(event) => {
                  setPage(0)
                  setIsActive(event.target.value)
                }}
              >
                <option value="">Any active state</option>
                <option value="true">Active</option>
                <option value="false">Inactive</option>
              </CFormSelect>
            </CCol>
            <CCol md={3}>
              <CFormSelect
                value={departmentId}
                aria-label="Filter users by department"
                onChange={(event) => {
                  setPage(0)
                  setDepartmentId(event.target.value)
                }}
              >
                <option value="">All departments</option>
                {departments.map((department) => (
                  <option key={department.id} value={department.id}>
                    {department.name}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={2}>
              <CFormSelect
                value={direction}
                aria-label="Sort users"
                onChange={(event) => {
                  setPage(0)
                  setDirection(event.target.value)
                }}
              >
                <option value="DESC">Newest</option>
                <option value="ASC">Oldest</option>
              </CFormSelect>
            </CCol>
          </CRow>

          {loading ? (
            <LoadingState label="Loading users..." />
          ) : users.length ? (
            <>
              <CTable align="middle" responsive hover aria-label="Users table">
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>User</CTableHeaderCell>
                    <CTableHeaderCell>Role</CTableHeaderCell>
                    <CTableHeaderCell>Status</CTableHeaderCell>
                    <CTableHeaderCell>Active</CTableHeaderCell>
                    <CTableHeaderCell>Department</CTableHeaderCell>
                    <CTableHeaderCell>Created</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {users.map((item) => (
                    <CTableRow key={item.id}>
                      <CTableDataCell>
                        <div className="fw-semibold">{item.fullName || '-'}</div>
                        <div className="small text-body-secondary">{item.email || '-'}</div>
                      </CTableDataCell>
                      <CTableDataCell>
                        <CBadge color={item.role === 'ADMIN' ? 'primary' : 'info'}>
                          {formatLabel(item.role)}
                        </CBadge>
                      </CTableDataCell>
                      <CTableDataCell>
                        <StatusBadge value={item.status} />
                      </CTableDataCell>
                      <CTableDataCell>
                        <StatusBadge type="active" value={item.isActive} />
                      </CTableDataCell>
                      <CTableDataCell>{item.departmentName || '-'}</CTableDataCell>
                      <CTableDataCell>{formatDateTime(item.createdAt)}</CTableDataCell>
                      <CTableDataCell className="text-end">
                        <div className="d-inline-flex gap-2">
                          <CButton
                            color="primary"
                            variant="outline"
                            size="sm"
                            aria-label={`View user ${item.id}`}
                            onClick={() => openDetail(item.id)}
                          >
                            <CIcon icon={cilInfo} />
                          </CButton>
                          <CButton
                            color={item.isActive ? 'warning' : 'success'}
                            variant="outline"
                            size="sm"
                            disabled={saving || isCurrentUser(item.id)}
                            aria-label={
                              item.isActive
                                ? `Deactivate user ${item.id}`
                                : `Activate user ${item.id}`
                            }
                            onClick={() =>
                              setConfirmTarget({ ...item, nextActive: !item.isActive })
                            }
                          >
                            {item.isActive ? 'Deactivate' : 'Activate'}
                          </CButton>
                        </div>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">{pageInfo.totalElements} users</div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState title="No users found" description="Adjust filters and try again." />
          )}
        </CCardBody>
      </CCard>

      <CModal visible={Boolean(detail) || detailLoading} onClose={() => setDetail(null)} size="lg">
        <CModalHeader>
          <CModalTitle>User detail</CModalTitle>
        </CModalHeader>
        <CModalBody>
          {detailLoading ? (
            <LoadingState label="Loading user detail..." />
          ) : detail ? (
            <>
              <CRow className="g-3 mb-4">
                <CCol md={6}>
                  <div className="small text-body-secondary">Full name</div>
                  <div className="fw-semibold text-break">{detail.fullName || '-'}</div>
                </CCol>
                <CCol md={6}>
                  <div className="small text-body-secondary">Email</div>
                  <div className="text-break">{detail.email || '-'}</div>
                </CCol>
                <CCol md={6}>
                  <div className="small text-body-secondary">Phone</div>
                  <div>{detail.phone || '-'}</div>
                </CCol>
                <CCol md={3}>
                  <div className="small text-body-secondary">Role</div>
                  <CBadge color={detail.role === 'ADMIN' ? 'primary' : 'info'}>
                    {formatLabel(detail.role)}
                  </CBadge>
                </CCol>
                <CCol md={3}>
                  <div className="small text-body-secondary">Active</div>
                  <CBadge color={booleanStatusColor(detail.isActive)}>
                    {detail.isActive ? 'Active' : 'Inactive'}
                  </CBadge>
                </CCol>
                <CCol md={6}>
                  <div className="small text-body-secondary">Status</div>
                  <StatusBadge value={detail.status} />
                </CCol>
                <CCol md={6}>
                  <div className="small text-body-secondary">Created</div>
                  <div>{formatDateTime(detail.createdAt)}</div>
                </CCol>
              </CRow>

              <div className="d-flex flex-wrap gap-2 mb-4">
                <CButton
                  color={detail.isActive ? 'warning' : 'success'}
                  variant="outline"
                  disabled={saving || isCurrentUser(detail.id)}
                  onClick={() => setConfirmTarget({ ...detail, nextActive: !detail.isActive })}
                >
                  {detail.isActive ? 'Deactivate account' : 'Activate account'}
                </CButton>
              </div>

              {detail.role === 'STAFF' && (
                <CRow className="g-2">
                  <CCol md={8}>
                    <CFormSelect
                      label="Department"
                      value={assignDepartmentId}
                      onChange={(event) => setAssignDepartmentId(event.target.value)}
                    >
                      <option value="">Select department</option>
                      {departments.map((department) => (
                        <option key={department.id} value={department.id}>
                          {department.name}
                        </option>
                      ))}
                    </CFormSelect>
                  </CCol>
                  <CCol md={4} className="d-flex align-items-end">
                    <CButton
                      color="primary"
                      className="w-100"
                      onClick={handleDepartmentAssign}
                      disabled={saving || !assignDepartmentId || selectedSameDepartment}
                    >
                      {saving && <CSpinner component="span" size="sm" className="me-2" />}
                      Update department
                    </CButton>
                  </CCol>
                </CRow>
              )}
            </>
          ) : null}
        </CModalBody>
        <CModalFooter>
          <CButton color="secondary" variant="outline" onClick={() => setDetail(null)}>
            Close
          </CButton>
        </CModalFooter>
      </CModal>

      <ConfirmDialog
        visible={Boolean(confirmTarget)}
        title={confirmTarget?.nextActive ? 'Activate user' : 'Deactivate user'}
        message={`${
          confirmTarget?.nextActive ? 'Activate' : 'Deactivate'
        } ${confirmTarget?.fullName || confirmTarget?.email || 'this user'}?`}
        confirmLabel={confirmTarget?.nextActive ? 'Activate' : 'Deactivate'}
        confirmColor={confirmTarget?.nextActive ? 'success' : 'warning'}
        loading={saving}
        onCancel={() => setConfirmTarget(null)}
        onConfirm={handleStatusUpdate}
      />
    </>
  )
}

export default Users
