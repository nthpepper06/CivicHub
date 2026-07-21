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
  createCategory,
  getCategories,
  updateCategory,
  updateCategoryStatus,
} from '../../api/categoryService'
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
import { booleanStatusColor, formatDateTime } from '../../utils/display'

const emptyForm = { name: '', description: '', icon: '' }

const Categories = () => {
  const [categories, setCategories] = useState([])
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

  const loadCategories = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getCategories({
        page,
        size: 10,
        search: debouncedSearch.trim(),
        isActive: activeFilter,
      })
      setCategories(data.content)
      setPageInfo(data)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [activeFilter, debouncedSearch, page])

  useEffect(() => {
    const loadTimer = window.setTimeout(() => {
      loadCategories()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadCategories])

  const openCreate = () => {
    setEditing(null)
    setForm(emptyForm)
    setValidated(false)
    setModalVisible(true)
  }

  const openEdit = (category) => {
    setEditing(category)
    setForm({
      name: category.name || '',
      description: category.description || '',
      icon: category.icon || '',
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

    if (
      !form.name.trim() ||
      form.name.length > 100 ||
      form.description.length > 2000 ||
      form.icon.length > 500
    ) {
      return
    }

    const payload = {
      name: form.name.trim(),
      description: form.description.trim(),
      icon: form.icon.trim(),
    }

    setSaving(true)

    try {
      if (editing) {
        await updateCategory(editing.id, payload)
        setSuccess('Category updated.')
      } else {
        await createCategory(payload)
        setSuccess('Category created.')
      }

      closeModal()
      await loadCategories()
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
      await updateCategoryStatus(confirmTarget.id, !confirmTarget.isActive)
      setSuccess(confirmTarget.isActive ? 'Category deactivated.' : 'Category activated.')
      setConfirmTarget(null)
      await loadCategories()
    } catch (statusError) {
      setError(getApiErrorMessage(statusError))
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <strong>Categories</strong>
          <CButton color="primary" onClick={openCreate}>
            <CIcon icon={cilPlus} className="me-2" />
            Add category
          </CButton>
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
                  placeholder="Search categories"
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
            <LoadingState label="Loading categories..." />
          ) : categories.length ? (
            <>
              <CTable align="middle" responsive hover>
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>Name</CTableHeaderCell>
                    <CTableHeaderCell>Description</CTableHeaderCell>
                    <CTableHeaderCell>Icon</CTableHeaderCell>
                    <CTableHeaderCell>Status</CTableHeaderCell>
                    <CTableHeaderCell>Updated</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {categories.map((category) => (
                    <CTableRow key={category.id}>
                      <CTableDataCell className="fw-semibold">{category.name}</CTableDataCell>
                      <CTableDataCell>{category.description || '-'}</CTableDataCell>
                      <CTableDataCell>{category.icon || '-'}</CTableDataCell>
                      <CTableDataCell>
                        <CBadge color={booleanStatusColor(category.isActive)}>
                          {category.isActive ? 'Active' : 'Inactive'}
                        </CBadge>
                      </CTableDataCell>
                      <CTableDataCell>
                        {formatDateTime(category.updatedAt || category.createdAt)}
                      </CTableDataCell>
                      <CTableDataCell className="text-end">
                        <CButton
                          color="secondary"
                          variant="outline"
                          size="sm"
                          className="me-2"
                          title="Edit category"
                          aria-label={`Edit ${category.name}`}
                          onClick={() => openEdit(category)}
                        >
                          <CIcon icon={cilPencil} />
                        </CButton>
                        <CButton
                          color={category.isActive ? 'danger' : 'success'}
                          variant="outline"
                          size="sm"
                          title={category.isActive ? 'Deactivate category' : 'Activate category'}
                          aria-label={`${category.isActive ? 'Deactivate' : 'Activate'} ${category.name}`}
                          onClick={() => setConfirmTarget(category)}
                        >
                          <CIcon icon={category.isActive ? cilXCircle : cilCheck} />
                        </CButton>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">{pageInfo.totalElements} categories</div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState
              title="No categories found"
              description="Create a category or adjust the filters."
            />
          )}
        </CCardBody>
      </CCard>

      <CModal visible={modalVisible} onClose={closeModal} alignment="center">
        <CForm noValidate validated={validated} onSubmit={handleSubmit}>
          <CModalHeader>
            <CModalTitle>{editing ? 'Edit category' : 'Add category'}</CModalTitle>
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
              className="mb-3"
              label="Description"
              value={form.description}
              maxLength={2000}
              rows={4}
              onChange={(event) =>
                setForm((current) => ({ ...current, description: event.target.value }))
              }
            />
            <CFormInput
              label="Icon"
              value={form.icon}
              maxLength={500}
              onChange={(event) => setForm((current) => ({ ...current, icon: event.target.value }))}
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
        title={confirmTarget?.isActive ? 'Deactivate category' : 'Activate category'}
        message={`Are you sure you want to ${confirmTarget?.isActive ? 'deactivate' : 'activate'} ${
          confirmTarget?.name || 'this category'
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

export default Categories
