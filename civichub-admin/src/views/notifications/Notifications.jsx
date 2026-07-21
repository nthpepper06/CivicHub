import React, { useCallback, useEffect, useState } from 'react'
import {
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CFormSelect,
  CRow,
  CSpinner,
  CTable,
  CTableBody,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
} from '@coreui/react'

import {
  getNotifications,
  getUnreadNotificationCount,
  markAllNotificationsAsRead,
  markNotificationAsRead,
} from '../../api/notificationService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  EmptyState,
  ErrorAlert,
  LoadingState,
  PagePagination,
} from '../../components/admin/AdminPageState'
import AdminToast from '../../components/admin/AdminToast'
import { downloadCsv } from '../../utils/csvExport'
import { formatDateTime, formatLabel } from '../../utils/display'

const Notifications = () => {
  const [notifications, setNotifications] = useState([])
  const [pageInfo, setPageInfo] = useState({ page: 0, totalPages: 0, totalElements: 0 })
  const [page, setPage] = useState(0)
  const [unread, setUnread] = useState('')
  const [unreadCount, setUnreadCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const loadNotifications = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const [pageData, countData] = await Promise.all([
        getNotifications({
          page,
          size: 10,
          unread,
          sortBy: 'createdAt',
          direction: 'DESC',
        }),
        getUnreadNotificationCount(),
      ])

      setNotifications(pageData.content)
      setPageInfo(pageData)
      setUnreadCount(countData?.count || 0)
    } catch (loadError) {
      setError(getApiErrorMessage(loadError))
    } finally {
      setLoading(false)
    }
  }, [page, unread])

  useEffect(() => {
    const loadTimer = window.setTimeout(() => {
      loadNotifications()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [loadNotifications])

  const markRead = async (id) => {
    setSaving(true)
    setError('')
    setSuccess('')

    try {
      await markNotificationAsRead(id)
      setSuccess('Notification marked as read.')
      await loadNotifications()
      window.dispatchEvent(new Event('civichub:notifications-updated'))
    } catch (readError) {
      setError(getApiErrorMessage(readError))
    } finally {
      setSaving(false)
    }
  }

  const markAllRead = async () => {
    setSaving(true)
    setError('')
    setSuccess('')

    try {
      const result = await markAllNotificationsAsRead()
      setSuccess(`${result?.updatedCount || 0} notifications marked as read.`)
      await loadNotifications()
      window.dispatchEvent(new Event('civichub:notifications-updated'))
    } catch (readError) {
      setError(getApiErrorMessage(readError))
    } finally {
      setSaving(false)
    }
  }

  const exportCurrentPage = () => {
    downloadCsv({
      filename: 'civichub-notifications-current-page.csv',
      columns: [
        { header: 'ID', value: (notification) => notification.id },
        { header: 'Title', value: (notification) => notification.title },
        { header: 'Message', value: (notification) => notification.message },
        { header: 'Type', value: (notification) => notification.type },
        { header: 'Read', value: (notification) => (notification.read ? 'Read' : 'Unread') },
        { header: 'Read At', value: (notification) => notification.readAt },
        { header: 'Created At', value: (notification) => notification.createdAt },
      ],
      rows: notifications,
    })
  }

  return (
    <>
      <AdminToast message={success} onClose={() => setSuccess('')} />
      <CCard className="mb-4">
        <CCardHeader className="d-flex flex-wrap gap-2 align-items-center justify-content-between">
          <div>
            <strong>Notifications</strong>
            <CBadge color="warning" className="ms-2">
              {unreadCount} unread
            </CBadge>
          </div>
          <div className="d-flex flex-wrap gap-2">
            <CButton
              color="secondary"
              variant="outline"
              onClick={exportCurrentPage}
              disabled={loading || notifications.length === 0}
            >
              Export current page CSV
            </CButton>
            <CButton
              color="primary"
              variant="outline"
              onClick={markAllRead}
              disabled={saving || unreadCount === 0}
            >
              {saving && <CSpinner component="span" size="sm" className="me-2" />}
              Mark all read
            </CButton>
            <CButton
              color="secondary"
              variant="outline"
              onClick={loadNotifications}
              disabled={loading}
            >
              Refresh
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <ErrorAlert message={error} />

          <CRow className="mb-3">
            <CCol md={4}>
              <CFormSelect
                value={unread}
                onChange={(event) => {
                  setPage(0)
                  setUnread(event.target.value)
                }}
              >
                <option value="">All notifications</option>
                <option value="true">Unread only</option>
                <option value="false">Read only</option>
              </CFormSelect>
            </CCol>
          </CRow>

          {loading ? (
            <LoadingState label="Loading notifications..." />
          ) : notifications.length ? (
            <>
              <CTable align="middle" responsive hover aria-label="Notifications table">
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell>Title</CTableHeaderCell>
                    <CTableHeaderCell>Message</CTableHeaderCell>
                    <CTableHeaderCell>Type</CTableHeaderCell>
                    <CTableHeaderCell>Status</CTableHeaderCell>
                    <CTableHeaderCell>Created</CTableHeaderCell>
                    <CTableHeaderCell className="text-end">Actions</CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody>
                  {notifications.map((notification) => (
                    <CTableRow key={notification.id}>
                      <CTableDataCell className="fw-semibold">
                        {notification.title || '-'}
                      </CTableDataCell>
                      <CTableDataCell>{notification.message || '-'}</CTableDataCell>
                      <CTableDataCell>{formatLabel(notification.type)}</CTableDataCell>
                      <CTableDataCell>
                        <CBadge color={notification.read ? 'secondary' : 'warning'}>
                          {notification.read ? 'Read' : 'Unread'}
                        </CBadge>
                      </CTableDataCell>
                      <CTableDataCell>{formatDateTime(notification.createdAt)}</CTableDataCell>
                      <CTableDataCell className="text-end">
                        <CButton
                          color="primary"
                          variant="outline"
                          size="sm"
                          disabled={saving || notification.read}
                          onClick={() => markRead(notification.id)}
                        >
                          Mark read
                        </CButton>
                      </CTableDataCell>
                    </CTableRow>
                  ))}
                </CTableBody>
              </CTable>
              <div className="small text-body-secondary">
                {pageInfo.totalElements} notifications
              </div>
              <PagePagination
                page={pageInfo.page}
                totalPages={pageInfo.totalPages}
                onChange={setPage}
              />
            </>
          ) : (
            <EmptyState title="No notifications found" />
          )}
        </CCardBody>
      </CCard>
    </>
  )
}

export default Notifications
