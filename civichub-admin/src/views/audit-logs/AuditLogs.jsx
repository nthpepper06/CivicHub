import React, { useCallback, useEffect, useState } from 'react'
import {
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CFormInput,
  CFormSelect,
  CInputGroup,
  CModal,
  CModalBody,
  CModalFooter,
  CModalHeader,
  CModalTitle,
  CRow,
  CTable,
  CTableBody,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
} from '@coreui/react'
import CIcon from '@coreui/icons-react'
import { cilInfo, cilSearch } from '@coreui/icons'

import { getAuditLog, getAuditLogs } from '../../api/auditLogService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  EmptyState,
  ErrorAlert,
  LoadingState,
  PagePagination,
} from '../../components/admin/AdminPageState'
import useDebouncedValue from '../../hooks/useDebouncedValue'
import { downloadCsv } from '../../utils/csvExport'
import { formatDateTime, formatLabel } from '../../utils/display'

const actions = [
  'CATEGORY_CREATED',
  'CATEGORY_UPDATED',
  'CATEGORY_ACTIVATED',
  'CATEGORY_DEACTIVATED',
  'DEPARTMENT_CREATED',
  'DEPARTMENT_UPDATED',
  'DEPARTMENT_ACTIVATED',
  'DEPARTMENT_DEACTIVATED',
  'REPORT_ASSIGNED',
  'REPORT_REASSIGNED',
  'REPORT_STATUS_CHANGED',
  'REPORT_CANCELLED',
]
const entityTypes = ['CATEGORY', 'DEPARTMENT', 'REPORT']

const AuditLogs = () => {
  const [logs, setLogs] = useState([])
  const [pageInfo, setPageInfo] = useState({ page: 0, totalPages: 0, totalElements: 0 })
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [action, setAction] = useState('')
  const [entityType, setEntityType] = useState('')
  const [actorId, setActorId] = useState('')
  const [createdFrom, setCreatedFrom] = useState('')
  const [createdTo, setCreatedTo] = useState('')
  const [loading, setLoading] = useState(true)
  const [detailLoading, setDetailLoading] = useState(false)
  const [error, setError] = useState('')
  const [detail, setDetail] = useState(null)
  const debouncedSearch = useDebouncedValue(search, 400)

  const loadLogs = useCallback(async () => {
    if (createdFrom && createdTo && createdFrom > createdTo) {
      setError('From date must be before or equal to To date.')
      setLoading(false)
      return
    }

    setLoading(true)
    setError('')

    try {
      const data = await getAuditLogs({
        page,
        size: 20,
        search: debouncedSearch.trim(),
        action,
        entityType,
        actorId,
        createdFrom: createdFrom ? `${createdFrom}T00:00:00` : '',
        createdTo: createdTo ? `${createdTo}T23:59:59` : '',
        sortBy: 'createdAt',
        direction: 'DESC',
      })
      setLogs(data.content)
      setPageInfo(data)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [action, actorId, createdFrom, createdTo, debouncedSearch, entityType, page])

  useEffect(() => {
    const loadTimer = window.setTimeout(() => {
      loadLogs()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadLogs])

  const openDetail = async (id) => {
    setDetailLoading(true)
    setError('')

    try {
      setDetail(await getAuditLog(id))
    } catch (detailError) {
      setError(getApiErrorMessage(detailError))
    } finally {
      setDetailLoading(false)
    }
  }

  const clearFilters = () => {
    setPage(0)
    setSearch('')
    setAction('')
    setEntityType('')
    setActorId('')
    setCreatedFrom('')
    setCreatedTo('')
  }

  const exportCurrentPage = () => {
    downloadCsv({
      filename: 'civichub-audit-logs-current-page.csv',
      columns: [
        { header: 'ID', value: (log) => log.id },
        { header: 'Actor ID', value: (log) => log.actorId },
        { header: 'Actor Name', value: (log) => log.actorName },
        { header: 'Actor Role', value: (log) => log.actorRole },
        { header: 'Action', value: (log) => log.action },
        { header: 'Entity Type', value: (log) => log.entityType },
        { header: 'Entity ID', value: (log) => log.entityId },
        { header: 'Description', value: (log) => log.description },
        { header: 'Created At', value: (log) => log.createdAt },
      ],
      rows: logs,
    })
  }

  return (
    <>
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <strong>Audit Logs</strong>
          <CButton
            color="secondary"
            variant="outline"
            onClick={exportCurrentPage}
            disabled={loading || logs.length === 0}
          >
            Export current page CSV
          </CButton>
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
                  placeholder="Search audit logs"
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
                value={action}
                onChange={(event) => {
                  setPage(0)
                  setAction(event.target.value)
                }}
              >
                <option value="">All actions</option>
                {actions.map((item) => (
                  <option key={item} value={item}>
                    {formatLabel(item)}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={2}>
              <CFormSelect
                value={entityType}
                onChange={(event) => {
                  setPage(0)
                  setEntityType(event.target.value)
                }}
              >
                <option value="">All entities</option>
                {entityTypes.map((item) => (
                  <option key={item} value={item}>
                    {formatLabel(item)}
                  </option>
                ))}
              </CFormSelect>
            </CCol>
            <CCol md={3}>
              <CFormInput
                type="number"
                min={1}
                placeholder="Actor user ID"
                aria-label="Filter by actor user ID"
                value={actorId}
                onChange={(event) => {
                  setPage(0)
                  setActorId(event.target.value)
                }}
              />
            </CCol>
            <CCol md={3}>
              <CFormInput
                type="date"
                label="From"
                value={createdFrom}
                onChange={(event) => {
                  setPage(0)
                  setCreatedFrom(event.target.value)
                }}
              />
            </CCol>
            <CCol md={3}>
              <CFormInput
                type="date"
                label="To"
                value={createdTo}
                onChange={(event) => {
                  setPage(0)
                  setCreatedTo(event.target.value)
                }}
              />
            </CCol>
            <CCol md={3} className="d-flex align-items-end">
              <CButton color="secondary" variant="outline" onClick={clearFilters}>
                Clear filters
              </CButton>
            </CCol>
          </CRow>

          {loading ? (
            <LoadingState label="Loading audit logs..." />
          ) : logs.length ? (
            <>
              <CTable align="middle" responsive hover aria-label="Audit logs table">
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>Actor</CTableHeaderCell>
                    <CTableHeaderCell>Action</CTableHeaderCell>
                    <CTableHeaderCell>Entity</CTableHeaderCell>
                    <CTableHeaderCell>Description</CTableHeaderCell>
                    <CTableHeaderCell>Time</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {logs.map((log) => (
                    <CTableRow key={log.id}>
                      <CTableDataCell>
                        <div className="fw-semibold">{log.actorName || `User #${log.actorId}`}</div>
                        <div className="small text-body-secondary">
                          {formatLabel(log.actorRole)}
                        </div>
                      </CTableDataCell>
                      <CTableDataCell>
                        <CBadge color="info">{formatLabel(log.action)}</CBadge>
                      </CTableDataCell>
                      <CTableDataCell>
                        {formatLabel(log.entityType)} #{log.entityId}
                      </CTableDataCell>
                      <CTableDataCell>{log.description || '-'}</CTableDataCell>
                      <CTableDataCell>{formatDateTime(log.createdAt)}</CTableDataCell>
                      <CTableDataCell className="text-end">
                        <CButton
                          color="primary"
                          variant="outline"
                          size="sm"
                          aria-label={`View audit log ${log.id}`}
                          onClick={() => openDetail(log.id)}
                        >
                          <CIcon icon={cilInfo} />
                        </CButton>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">{pageInfo.totalElements} audit logs</div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState title="No audit logs found" />
          )}
        </CCardBody>
      </CCard>

      <CModal visible={Boolean(detail) || detailLoading} onClose={() => setDetail(null)} size="lg">
        <CModalHeader>
          <CModalTitle>Audit log detail</CModalTitle>
        </CModalHeader>
        <CModalBody>
          {detailLoading ? (
            <LoadingState label="Loading audit detail..." />
          ) : detail ? (
            <CRow className="g-3">
              <CCol md={6}>
                <div className="small text-body-secondary">Actor</div>
                <div>{detail.actorName || `User #${detail.actorId}`}</div>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Role</div>
                <div>{formatLabel(detail.actorRole)}</div>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Action</div>
                <div>{formatLabel(detail.action)}</div>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Entity</div>
                <div>
                  {formatLabel(detail.entityType)} #{detail.entityId}
                </div>
              </CCol>
              <CCol xs={12}>
                <div className="small text-body-secondary">Description</div>
                <div>{detail.description || '-'}</div>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Old values</div>
                <pre className="bg-body-tertiary p-3 rounded small mb-0">
                  {detail.oldValues || '-'}
                </pre>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">New values</div>
                <pre className="bg-body-tertiary p-3 rounded small mb-0">
                  {detail.newValues || '-'}
                </pre>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Created</div>
                <div>{formatDateTime(detail.createdAt)}</div>
              </CCol>
              <CCol md={6}>
                <div className="small text-body-secondary">Correlation ID</div>
                <div>{detail.correlationId || '-'}</div>
              </CCol>
            </CRow>
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

export default AuditLogs
