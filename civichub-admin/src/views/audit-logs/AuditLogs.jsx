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
  const [loading, setLoading] = useState(true)
  const [detailLoading, setDetailLoading] = useState(false)
  const [error, setError] = useState('')
  const [detail, setDetail] = useState(null)
  const debouncedSearch = useDebouncedValue(search, 400)

  const loadLogs = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const data = await getAuditLogs({
        page,
        size: 20,
        search: debouncedSearch.trim(),
        action,
        entityType,
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
  }, [action, debouncedSearch, entityType, page])

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

  return (
    <>
      <CCard className="mb-4">
        <CCardHeader>
          <strong>Audit Logs</strong>
        </CCardHeader>
        <CCardBody>
          <ErrorAlert message={error} />

          <CRow className="g-2 mb-3">
            <CCol md={5}>
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
            <CCol md={4}>
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
            <CCol md={3}>
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
          </CRow>

          {loading ? (
            <LoadingState label="Loading audit logs..." />
          ) : logs.length ? (
            <>
              <CTable align="middle" responsive hover>
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
