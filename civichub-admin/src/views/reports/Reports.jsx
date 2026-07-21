import React, { useCallback, useEffect, useState } from 'react'
import {
  CAlert,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CFormSelect,
  CImage,
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

import { getAuditLogs } from '../../api/auditLogService'
import { getCategories } from '../../api/categoryService'
import { getDepartments } from '../../api/departmentService'
import { assignReportDepartment, getReport, getReports } from '../../api/reportService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  EmptyState,
  ErrorAlert,
  LoadingState,
  PagePagination,
  StatusBadge,
} from '../../components/admin/AdminPageState'
import AdminToast from '../../components/admin/AdminToast'
import useDebouncedValue from '../../hooks/useDebouncedValue'
import { formatDateTime, formatLabel } from '../../utils/display'

const statuses = ['PENDING', 'RECEIVED', 'IN_PROGRESS', 'RESOLVED', 'REJECTED', 'CANCELLED']

const Reports = () => {
  const [reports, setReports] = useState([])
  const [categories, setCategories] = useState([])
  const [departments, setDepartments] = useState([])
  const [pageInfo, setPageInfo] = useState({ page: 0, totalPages: 0, totalElements: 0 })
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [direction, setDirection] = useState('DESC')
  const [loading, setLoading] = useState(true)
  const [detailLoading, setDetailLoading] = useState(false)
  const [timelineLoading, setTimelineLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [detail, setDetail] = useState(null)
  const [timeline, setTimeline] = useState([])
  const [assignDepartmentId, setAssignDepartmentId] = useState('')
  const debouncedSearch = useDebouncedValue(search, 400)
  const selectedSameDepartment =
    detail?.departmentId && Number(assignDepartmentId) === Number(detail.departmentId)

  const loadReports = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getReports({
        page,
        size: 10,
        search: debouncedSearch.trim(),
        status,
        categoryId,
        departmentId,
        sortBy: 'createdAt',
        direction,
      })
      setReports(data.content)
      setPageInfo(data)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [categoryId, debouncedSearch, departmentId, direction, page, status])

  useEffect(() => {
    const loadTimer = window.setTimeout(() => {
      loadReports()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadReports])

  useEffect(() => {
    const loadFilters = async () => {
      try {
        const [categoryData, departmentData] = await Promise.all([
          getCategories({ page: 0, size: 100, isActive: true }),
          getDepartments({ page: 0, size: 100, isActive: true }),
        ])
        setCategories(categoryData.content)
        setDepartments(departmentData.content)
      } catch {
        setCategories([])
        setDepartments([])
      }
    }

    loadFilters()
  }, [])

  const openDetail = async (reportId) => {
    setDetailLoading(true)
    setTimelineLoading(true)
    setError('')
    setTimeline([])

    try {
      const data = await getReport(reportId)
      setDetail(data)
      setAssignDepartmentId(data?.departmentId || '')
    } catch (detailError) {
      setError(getApiErrorMessage(detailError))
    } finally {
      setDetailLoading(false)
    }

    try {
      const timelineData = await getAuditLogs({
        page: 0,
        size: 20,
        entityType: 'REPORT',
        entityId: reportId,
        sortBy: 'createdAt',
        direction: 'DESC',
      })
      setTimeline(timelineData.content)
    } catch {
      setTimeline([])
    } finally {
      setTimelineLoading(false)
    }
  }

  const handleAssign = async () => {
    if (!detail || !assignDepartmentId) {
      return
    }

    setSaving(true)
    setError('')
    setSuccess('')

    try {
      const updated = await assignReportDepartment(detail.id, Number(assignDepartmentId))
      setDetail(updated)
      setAssignDepartmentId(updated?.departmentId || '')
      setSuccess('Report department assigned.')
      await loadReports()
    } catch (assignError) {
      setError(getApiErrorMessage(assignError))
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader>
          <strong>Reports</strong>
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
                  placeholder="Search reports"
                  value={search}
                  onChange={(event) => {
                    setPage(0)
                    setSearch(event.target.value)
                  }}
                />
              </CInputGroup>
            </CCol>
            <CCol md={3}>
              <CFormSelect
                value={status}
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
            <CCol md={3}>
              <CFormSelect
                value={categoryId}
                aria-label="Filter reports by category"
                onChange={(event) => {
                  setPage(0)
                  setCategoryId(event.target.value)
                }}
              >
                <option value="">All categories</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={3}>
              <CFormSelect
                value={departmentId}
                aria-label="Filter reports by department"
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
                aria-label="Sort reports"
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
            <LoadingState label="Loading reports..." />
          ) : reports.length ? (
            <>
              <CTable align="middle" responsive hover aria-label="Reports table">
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>ID</CTableHeaderCell>
                    <CTableHeaderCell>Title</CTableHeaderCell>
                    <CTableHeaderCell>Citizen</CTableHeaderCell>
                    <CTableHeaderCell>Category</CTableHeaderCell>
                    <CTableHeaderCell>Department</CTableHeaderCell>
                    <CTableHeaderCell>Status</CTableHeaderCell>
                    <CTableHeaderCell>Created</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {reports.map((report) => (
                    <CTableRow key={report.id}>
                      <CTableDataCell>#{report.id}</CTableDataCell>
                      <CTableDataCell>
                        <div className="fw-semibold">{report.title || '-'}</div>
                        <div className="small text-body-secondary">{report.address || '-'}</div>
                      </CTableDataCell>
                      <CTableDataCell>{report.citizenName || '-'}</CTableDataCell>
                      <CTableDataCell>{report.categoryName || '-'}</CTableDataCell>
                      <CTableDataCell>{report.departmentName || '-'}</CTableDataCell>
                      <CTableDataCell>
                        <StatusBadge type="report" value={report.status} />
                      </CTableDataCell>
                      <CTableDataCell>{formatDateTime(report.createdAt)}</CTableDataCell>
                      <CTableDataCell className="text-end">
                        <CButton
                          color="primary"
                          variant="outline"
                          size="sm"
                          aria-label={`View report ${report.id}`}
                          onClick={() => openDetail(report.id)}
                        >
                          <CIcon icon={cilInfo} />
                        </CButton>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">{pageInfo.totalElements} reports</div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState
              title="No reports found"
              description="Adjust filters or wait for citizen reports."
            />
          )}
        </CCardBody>
      </CCard>

      <CModal visible={Boolean(detail) || detailLoading} onClose={() => setDetail(null)} size="lg">
        <CModalHeader>
          <CModalTitle>Report detail</CModalTitle>
        </CModalHeader>
        <CModalBody>
          {detailLoading ? (
            <LoadingState label="Loading report detail..." />
          ) : detail ? (
            <>
              <CRow className="g-3 mb-3">
                <CCol md={8}>
                  <h5>{detail.title || `Report #${detail.id}`}</h5>
                  <p className="text-body-secondary mb-2">{detail.description || '-'}</p>
                  <div>{detail.address || '-'}</div>
                </CCol>
                <CCol md={4}>
                  <div className="mb-2">
                    <StatusBadge type="report" value={detail.status} />
                  </div>
                  <div className="small text-body-secondary">Created</div>
                  <div>{formatDateTime(detail.createdAt)}</div>
                </CCol>
              </CRow>

              <CRow className="g-3 mb-4">
                <CCol md={4}>
                  <div className="small text-body-secondary">Citizen</div>
                  <div>{detail.citizenName || '-'}</div>
                </CCol>
                <CCol md={4}>
                  <div className="small text-body-secondary">Category</div>
                  <div>{detail.categoryName || '-'}</div>
                </CCol>
                <CCol md={4}>
                  <div className="small text-body-secondary">Department</div>
                  <div>{detail.departmentName || '-'}</div>
                </CCol>
              </CRow>

              <CAlert color="info">
                Report status updates are available through the staff report workflow. The backend
                does not expose an ADMIN status update endpoint.
              </CAlert>

              <CRow className="g-2 mb-4">
                <CCol md={8}>
                  <CFormSelect
                    label="Assign department"
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
                    onClick={handleAssign}
                    disabled={saving || !assignDepartmentId || selectedSameDepartment}
                  >
                    {saving && <CSpinner component="span" size="sm" className="me-2" />}
                    Assign
                  </CButton>
                </CCol>
              </CRow>

              {Array.isArray(detail.images) && detail.images.length ? (
                <CRow className="g-3">
                  {detail.images.map((image) => (
                    <CCol sm={6} lg={4} key={image.id || image.url}>
                      <CImage
                        src={image.url}
                        alt="Report attachment"
                        fluid
                        rounded
                        className="mb-2"
                      />
                      <CButton
                        color="secondary"
                        variant="outline"
                        size="sm"
                        component="a"
                        href={image.url}
                        target="_blank"
                        rel="noreferrer"
                        download
                      >
                        Download
                      </CButton>
                    </CCol>
                  ))}
                </CRow>
              ) : (
                <EmptyState title="No attachments" />
              )}

              <hr />
              <h6>Timeline</h6>
              {timelineLoading ? (
                <LoadingState label="Loading timeline..." />
              ) : timeline.length ? (
                <CTable responsive small aria-label="Report timeline">
                  <CTableHead>
                    <CTableRow>
                      <CTableHeaderCell>Time</CTableHeaderCell>
                      <CTableHeaderCell>Action</CTableHeaderCell>
                      <CTableHeaderCell>Actor</CTableHeaderCell>
                      <CTableHeaderCell>Description</CTableHeaderCell>
                    </CTableRow>
                  </CTableHead>
                  <CTableBody>
                    {timeline.map((item) => (
                      <CTableRow key={item.id}>
                        <CTableDataCell>{formatDateTime(item.createdAt)}</CTableDataCell>
                        <CTableDataCell>{formatLabel(item.action)}</CTableDataCell>
                        <CTableDataCell>{item.actorName || `User #${item.actorId}`}</CTableDataCell>
                        <CTableDataCell>{item.description || '-'}</CTableDataCell>
                      </CTableRow>
                    ))}
                  </CTableBody>
                </CTable>
              ) : (
                <EmptyState title="No timeline events" />
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
    </>
  )
}

export default Reports
