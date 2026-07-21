import React, { useCallback, useEffect, useState } from 'react'
import {
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CForm,
  CFormInput,
  CFormSelect,
  CFormTextarea,
  CInputGroup,
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
import { cilCheck, cilPencil, cilPlus, cilSearch, cilXCircle } from '@coreui/icons'

import {
  createDepartment,
  getDepartments,
  updateDepartment,
  updateDepartmentStatus,
} from '../../api/departmentService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  ConfirmModal,
  EmptyState,
  ErrorAlert,
  LoadingState,
  PagePagination,
} from '../../components/admin/AdminPageState'
import AdminToast from '../../components/admin/AdminToast'
import useDebouncedValue from '../../hooks/useDebouncedValue'
import { downloadCsv } from '../../utils/csvExport'
import { booleanStatusColor, formatDateTime } from '../../utils/display'

const emptyForm = { name: '', description: '' }

const Departments = () => {
  const [departments, setDepartments] = useState([])
  const [pageInfo, setPageInfo] = useState({ page: 0, totalPages: 0, totalElements: 0 })
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [activeFilter, setActiveFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [modalVisible, setModalVisible] = useState(false)
  const [editing, setEditing] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [validated, setValidated] = useState(false)
  const [confirmTarget, setConfirmTarget] = useState(null)
  const debouncedSearch = useDebouncedValue(search, 400)

  const loadDepartments = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getDepartments({
        page,
        size: 10,
        search: debouncedSearch.trim(),
        isActive: activeFilter,
      })
      setDepartments(data.content)
      setPageInfo(data)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [activeFilter, debouncedSearch, page])

  useEffect(() => {
    const loadTimer = window.setTimeout(() => {
      loadDepartments()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadDepartments])

  const openCreate = () => {
    setEditing(null)
    setForm(emptyForm)
    setValidated(false)
    setModalVisible(true)
  }

  const openEdit = (department) => {
    setEditing(department)
    setForm({
      name: department.name || '',
      description: department.description || '',
    })
    setValidated(false)
    setModalVisible(true)
  }

  const closeModal = () => {
    setModalVisible(false)
    setEditing(null)
    setForm(emptyForm)
    setValidated(false)
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setValidated(true)
    setError('')
    setSuccess('')

    if (!form.name.trim() || form.name.length > 100 || form.description.length > 2000) {
      return
    }

    const payload = {
      name: form.name.trim(),
      description: form.description.trim(),
    }

    setSaving(true)

    try {
      if (editing) {
        await updateDepartment(editing.id, payload)
        setSuccess('Department updated.')
      } else {
        await createDepartment(payload)
        setSuccess('Department created.')
      }

      closeModal()
      await loadDepartments()
    } catch (saveError) {
      setError(getApiErrorMessage(saveError))
    } finally {
      setSaving(false)
    }
  }

  const handleStatus = async () => {
    if (!confirmTarget) {
      return
    }

    setSaving(true)
    setError('')
    setSuccess('')

    try {
      await updateDepartmentStatus(confirmTarget.id, !confirmTarget.isActive)
      setSuccess(confirmTarget.isActive ? 'Department deactivated.' : 'Department activated.')
      setConfirmTarget(null)
      await loadDepartments()
    } catch (statusError) {
      setError(getApiErrorMessage(statusError))
    } finally {
      setSaving(false)
    }
  }

  const exportCurrentPage = () => {
    downloadCsv({
      filename: 'civichub-departments-current-page.csv',
      columns: [
        { header: 'ID', value: (department) => department.id },
        { header: 'Name', value: (department) => department.name },
        { header: 'Description', value: (department) => department.description },
        { header: 'Active', value: (department) => (department.isActive ? 'Active' : 'Inactive') },
        { header: 'Created At', value: (department) => department.createdAt },
        { header: 'Updated At', value: (department) => department.updatedAt },
      ],
      rows: departments,
    })
  }

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <strong>Departments</strong>
          <div className="d-flex flex-wrap gap-2">
            <CButton
              color="secondary"
              variant="outline"
              onClick={exportCurrentPage}
              disabled={loading || departments.length === 0}
            >
              Export current page CSV
            </CButton>
            <CButton color="primary" onClick={openCreate}>
              <CIcon icon={cilPlus} className="me-2" />
              Add department
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <ErrorAlert message={error} />

          <CRow className="g-2 mb-3">
            <CCol md={8}>
              <CInputGroup>
                <span className="input-group-text">
                  <CIcon icon={cilSearch} />
                </span>
                <CFormInput
                  placeholder="Search departments"
                  value={search}
                  onChange={(event) => {
                    setPage(0)
                    setSearch(event.target.value)
                  }}
                />
              </CInputGroup>
            </CCol>
            <CCol md={4}>
              <CFormSelect
                value={activeFilter}
                onChange={(event) => {
                  setPage(0)
                  setActiveFilter(event.target.value)
                }}
              >
                <option value="">All statuses</option>
                <option value="true">Active</option>
                <option value="false">Inactive</option>
              </CFormSelect>
            </CCol>
          </CRow>

          {loading ? (
            <LoadingState label="Loading departments..." />
          ) : departments.length ? (
            <>
              <CTable align="middle" responsive hover>
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>Name</CTableHeaderCell>
                    <CTableHeaderCell>Description</CTableHeaderCell>
                    <CTableHeaderCell>Status</CTableHeaderCell>
                    <CTableHeaderCell>Updated</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {departments.map((department) => (
                    <CTableRow key={department.id}>
                      <CTableDataCell className="fw-semibold">{department.name}</CTableDataCell>
                      <CTableDataCell>{department.description || '-'}</CTableDataCell>
                      <CTableDataCell>
                        <CBadge color={booleanStatusColor(department.isActive)}>
                          {department.isActive ? 'Active' : 'Inactive'}
                        </CBadge>
                      </CTableDataCell>
                      <CTableDataCell>
                        {formatDateTime(department.updatedAt || department.createdAt)}
                      </CTableDataCell>
                      <CTableDataCell className="text-end">
                        <CButton
                          color="secondary"
                          variant="outline"
                          size="sm"
                          className="me-2"
                          title="Edit department"
                          aria-label={`Edit ${department.name}`}
                          onClick={() => openEdit(department)}
                        >
                          <CIcon icon={cilPencil} />
                        </CButton>
                        <CButton
                          color={department.isActive ? 'danger' : 'success'}
                          variant="outline"
                          size="sm"
                          title={
                            department.isActive ? 'Deactivate department' : 'Activate department'
                          }
                          aria-label={`${department.isActive ? 'Deactivate' : 'Activate'} ${department.name}`}
                          onClick={() => setConfirmTarget(department)}
                        >
                          <CIcon icon={department.isActive ? cilXCircle : cilCheck} />
                        </CButton>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">{pageInfo.totalElements} departments</div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState
              title="No departments found"
              description="Create a department or adjust the filters."
            />
          )}
        </CCardBody>
      </CCard>

      <CModal visible={modalVisible} onClose={closeModal} alignment="center">
        <CForm noValidate validated={validated} onSubmit={handleSubmit}>
          <CModalHeader>
            <CModalTitle>{editing ? 'Edit department' : 'Add department'}</CModalTitle>
          </CModalHeader>
          <CModalBody>
            <CFormInput
              className="mb-3"
              label="Name"
              value={form.name}
              maxLength={100}
              onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
              required
            />
            <CFormTextarea
              label="Description"
              value={form.description}
              maxLength={2000}
              rows={4}
              onChange={(event) =>
                setForm((current) => ({ ...current, description: event.target.value }))
              }
            />
          </CModalBody>
          <CModalFooter>
            <CButton color="secondary" variant="outline" onClick={closeModal} disabled={saving}>
              Cancel
            </CButton>
            <CButton color="primary" type="submit" disabled={saving}>
              {saving && <CSpinner component="span" size="sm" className="me-2" />}
              Save
            </CButton>
          </CModalFooter>
        </CForm>
      </CModal>

      <ConfirmModal
        visible={Boolean(confirmTarget)}
        title={confirmTarget?.isActive ? 'Deactivate department' : 'Activate department'}
        message={`Are you sure you want to ${confirmTarget?.isActive ? 'deactivate' : 'activate'} ${
          confirmTarget?.name || 'this department'
        }?`}
        confirmLabel={confirmTarget?.isActive ? 'Deactivate' : 'Activate'}
        confirmColor={confirmTarget?.isActive ? 'danger' : 'success'}
        loading={saving}
        onCancel={() => setConfirmTarget(null)}
        onConfirm={handleStatus}
      />
    </>
  )
}

export default Departments
