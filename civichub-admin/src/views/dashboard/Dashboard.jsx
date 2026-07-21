import React, { useEffect, useMemo, useState } from 'react'
import {
  CButton,
  CButtonGroup,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CFormInput,
  CRow,
  CSpinner,
  CTable,
  CTableBody,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
} from '@coreui/react'
import { CChartBar, CChartDoughnut, CChartLine } from '@coreui/react-chartjs'

import {
  getCategoryStatistics,
  getDashboardSummary,
  getDepartmentStatistics,
  getMonthlyStatistics,
} from '../../api/dashboardService'
import { getReports } from '../../api/reportService'
import { getApiErrorMessage } from '../../api/apiUtils'
import {
  EmptyState,
  ErrorAlert,
  LoadingSkeleton,
  StatusBadge,
} from '../../components/admin/AdminPageState'
import { formatDateTime } from '../../utils/display'

const monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
]

const StatCard = ({ label, value, color = 'primary' }) => (
  <CCol sm={6} xl={3}>
    <CCard className={`mb-4 border-top border-top-4 border-top-${color}`}>
      <CCardBody>
        <div className="text-body-secondary text-truncate">{label}</div>
        <div className="fs-3 fw-semibold">{Number(value ?? 0).toLocaleString()}</div>
      </CCardBody>
    </CCard>
  </CCol>
)

const toDateInputValue = (date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}`
}

const toApiDateTime = (dateInput, endOfDay = false) =>
  `${dateInput}${endOfDay ? 'T23:59:59' : 'T00:00:00'}`

const getPresetRange = (preset) => {
  const now = new Date()
  const start = new Date(now)
  const end = new Date(now)

  if (preset === 'week') {
    const day = start.getDay() || 7
    start.setDate(start.getDate() - day + 1)
  }

  if (preset === 'month') {
    start.setDate(1)
  }

  if (preset === 'year') {
    start.setMonth(0, 1)
  }

  return {
    preset,
    from: toDateInputValue(start),
    to: toDateInputValue(end),
  }
}

const Dashboard = () => {
  const [summary, setSummary] = useState({})
  const [categories, setCategories] = useState([])
  const [departments, setDepartments] = useState([])
  const [monthly, setMonthly] = useState([])
  const [recentReports, setRecentReports] = useState([])
  const [loading, setLoading] = useState(true)
  const [recentLoading, setRecentLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [sectionErrors, setSectionErrors] = useState({})
  const [draftRange, setDraftRange] = useState(() => getPresetRange('month'))
  const [appliedRange, setAppliedRange] = useState(() => getPresetRange('month'))
  const [rangeError, setRangeError] = useState('')
  const [refreshIndex, setRefreshIndex] = useState(0)

  useEffect(() => {
    const loadDashboardStats = async () => {
      setLoading(true)
      setSectionErrors((current) => ({
        ...current,
        summary: '',
        categories: '',
        departments: '',
        monthly: '',
      }))

      const params = {
        from: appliedRange.from ? toApiDateTime(appliedRange.from) : undefined,
        to: appliedRange.to ? toApiDateTime(appliedRange.to, true) : undefined,
      }

      const results = await Promise.allSettled([
        getDashboardSummary(params),
        getCategoryStatistics(params),
        getDepartmentStatistics(params),
        getMonthlyStatistics(new Date().getFullYear(), params),
      ])

      const [summaryResult, categoryResult, departmentResult, monthlyResult] = results
      const nextErrors = {}

      if (summaryResult.status === 'fulfilled') {
        setSummary(summaryResult.value || {})
      } else {
        setSummary({})
        nextErrors.summary = getApiErrorMessage(summaryResult.reason)
      }

      if (categoryResult.status === 'fulfilled') {
        setCategories(Array.isArray(categoryResult.value) ? categoryResult.value : [])
      } else {
        setCategories([])
        nextErrors.categories = getApiErrorMessage(categoryResult.reason)
      }

      if (departmentResult.status === 'fulfilled') {
        setDepartments(Array.isArray(departmentResult.value) ? departmentResult.value : [])
      } else {
        setDepartments([])
        nextErrors.departments = getApiErrorMessage(departmentResult.reason)
      }

      if (monthlyResult.status === 'fulfilled') {
        setMonthly(Array.isArray(monthlyResult.value) ? monthlyResult.value : [])
      } else {
        setMonthly([])
        nextErrors.monthly = getApiErrorMessage(monthlyResult.reason)
      }

      setSectionErrors((current) => ({ ...current, ...nextErrors }))
      setLoading(false)
    }

    const loadTimer = window.setTimeout(() => {
      loadDashboardStats()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [appliedRange, refreshIndex])

  useEffect(() => {
    const loadRecentReports = async () => {
      setRecentLoading(true)
      setRefreshing(true)
      setSectionErrors((current) => ({ ...current, recent: '' }))

      try {
        const createdFrom = appliedRange.from ? toApiDateTime(appliedRange.from) : undefined
        const createdTo = appliedRange.to ? toApiDateTime(appliedRange.to, true) : undefined
        const recentData = await getReports({
          page: 0,
          size: 10,
          createdFrom,
          createdTo,
          sortBy: 'createdAt',
          direction: 'DESC',
        })
        setRecentReports(recentData.content)
      } catch (recentError) {
        setRecentReports([])
        setSectionErrors((current) => ({ ...current, recent: getApiErrorMessage(recentError) }))
      } finally {
        setRecentLoading(false)
        setRefreshing(false)
      }
    }

    const loadTimer = window.setTimeout(() => {
      loadRecentReports()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [appliedRange, refreshIndex])

  const monthlyChart = useMemo(() => {
    const byMonth = new Map(monthly.map((item) => [item.month, item]))

    return monthLabels.map((_, index) => byMonth.get(index + 1) || {})
  }, [monthly])

  const handlePreset = (preset) => {
    setDraftRange(getPresetRange(preset))
    setRangeError('')
  }

  const handleRangeChange = (field, value) => {
    setDraftRange((current) => ({ ...current, preset: 'custom', [field]: value }))
    setRangeError('')
  }

  const applyRange = () => {
    if (draftRange.from && draftRange.to && draftRange.from > draftRange.to) {
      setRangeError('From date must be before or equal to To date.')
      return
    }

    setRangeError('')
    setAppliedRange(draftRange)
  }

  const resetRange = () => {
    const nextRange = getPresetRange('month')

    setDraftRange(nextRange)
    setAppliedRange(nextRange)
    setRangeError('')
  }

  const refreshDashboard = () => {
    if (draftRange.from && draftRange.to && draftRange.from > draftRange.to) {
      setRangeError('From date must be before or equal to To date.')
      return
    }

    setRangeError('')
    setAppliedRange(draftRange)
    setRefreshIndex((current) => current + 1)
  }

  if (loading) {
    return <LoadingSkeleton rows={8} />
  }

  return (
    <>
      <CCard className="mb-4">
        <CCardBody className="d-flex flex-wrap gap-2 align-items-end justify-content-between">
          <div className="d-flex flex-wrap gap-2 align-items-end">
            <div className="w-100 small text-body-secondary">
              Dashboard date range: {appliedRange.from || 'Any'} to {appliedRange.to || 'Any'}
            </div>
            <CButtonGroup role="group" aria-label="Dashboard date presets">
              {[
                ['today', 'Today'],
                ['week', 'This Week'],
                ['month', 'This Month'],
                ['year', 'This Year'],
              ].map(([value, label]) => (
                <CButton
                  key={value}
                  color="outline-primary"
                  active={draftRange.preset === value}
                  onClick={() => handlePreset(value)}
                >
                  {label}
                </CButton>
              ))}
            </CButtonGroup>
            <CFormInput
              type="date"
              label="From"
              value={draftRange.from}
              onChange={(event) => handleRangeChange('from', event.target.value)}
            />
            <CFormInput
              type="date"
              label="To"
              value={draftRange.to}
              onChange={(event) => handleRangeChange('to', event.target.value)}
            />
          </div>
          <div className="d-flex flex-wrap gap-2">
            <CButton color="primary" onClick={applyRange} disabled={refreshing}>
              Apply
            </CButton>
            <CButton color="secondary" variant="outline" onClick={resetRange} disabled={refreshing}>
              Reset
            </CButton>
            <CButton
              color="secondary"
              variant="outline"
              onClick={refreshDashboard}
              disabled={refreshing}
            >
              {refreshing && <CSpinner component="span" size="sm" className="me-2" />}
              Refresh
            </CButton>
          </div>
        </CCardBody>
      </CCard>
      <ErrorAlert message={rangeError} />
      <ErrorAlert message={sectionErrors.summary} />
      <CRow>
        <StatCard
          label="Total users"
          value={(summary.totalCitizens || 0) + (summary.totalStaff || 0)}
        />
        <StatCard label="Total reports" value={summary.totalReports} color="info" />
        <StatCard label="Pending reports" value={summary.pendingReports} color="warning" />
        <StatCard label="In progress" value={summary.inProgressReports} color="primary" />
        <StatCard label="Resolved reports" value={summary.resolvedReports} color="success" />
        <StatCard label="Rejected reports" value={summary.rejectedReports} color="danger" />
        <StatCard label="Departments" value={summary.totalDepartments} color="secondary" />
        <StatCard label="Categories" value={summary.totalCategories} color="secondary" />
      </CRow>

      <CRow>
        <CCol lg={8}>
          <CCard className="mb-4">
            <CCardHeader>Monthly reports</CCardHeader>
            <CCardBody>
              <ErrorAlert message={sectionErrors.monthly} />
              {monthly.length ? (
                <CChartLine
                  data={{
                    labels: monthLabels,
                    datasets: [
                      {
                        label: 'Total reports',
                        borderColor: '#321fdb',
                        backgroundColor: 'rgba(50, 31, 219, 0.08)',
                        data: monthlyChart.map((item) => item.totalReports || 0),
                      },
                      {
                        label: 'Resolved reports',
                        borderColor: '#2eb85c',
                        backgroundColor: 'rgba(46, 184, 92, 0.08)',
                        data: monthlyChart.map((item) => item.resolvedReports || 0),
                      },
                    ],
                  }}
                />
              ) : (
                <EmptyState
                  title="No monthly statistics"
                  description="The backend returned no monthly data."
                />
              )}
            </CCardBody>
          </CCard>
        </CCol>
        <CCol lg={4}>
          <CCard className="mb-4">
            <CCardHeader>Reports by category</CCardHeader>
            <CCardBody>
              <ErrorAlert message={sectionErrors.categories} />
              {categories.length ? (
                <CChartDoughnut
                  data={{
                    labels: categories.map(
                      (item) => item.categoryName || `Category ${item.categoryId}`,
                    ),
                    datasets: [
                      {
                        backgroundColor: [
                          '#321fdb',
                          '#39f',
                          '#2eb85c',
                          '#f9b115',
                          '#e55353',
                          '#6c757d',
                        ],
                        data: categories.map((item) => item.totalReports || 0),
                      },
                    ],
                  }}
                />
              ) : (
                <EmptyState title="No category statistics" />
              )}
            </CCardBody>
          </CCard>
        </CCol>
      </CRow>

      <CRow>
        <CCol lg={5}>
          <CCard className="mb-4">
            <CCardHeader>Reports by department</CCardHeader>
            <CCardBody>
              <ErrorAlert message={sectionErrors.departments} />
              {departments.length ? (
                <CChartBar
                  data={{
                    labels: departments.map(
                      (item) => item.departmentName || `Department ${item.departmentId}`,
                    ),
                    datasets: [
                      {
                        label: 'Reports',
                        backgroundColor: '#3399ff',
                        data: departments.map((item) => item.totalReports || 0),
                      },
                    ],
                  }}
                />
              ) : (
                <EmptyState title="No department statistics" />
              )}
            </CCardBody>
          </CCard>
        </CCol>
        <CCol lg={7}>
          <CCard className="mb-4">
            <CCardHeader>Recent reports</CCardHeader>
            <CCardBody>
              <ErrorAlert message={sectionErrors.recent} />
              {recentLoading ? (
                <LoadingSkeleton rows={3} />
              ) : recentReports.length ? (
                <CTable align="middle" responsive hover className="mb-0">
                  <CTableHead>
                    <CTableRow>
                      <CTableHeaderCell>Title</CTableHeaderCell>
                      <CTableHeaderCell>Citizen</CTableHeaderCell>
                      <CTableHeaderCell>Status</CTableHeaderCell>
                      <CTableHeaderCell>Created</CTableHeaderCell>
                    </CTableRow>
                  </CTableHead>
                  <CTableBody>
                    {recentReports.map((report) => (
                      <CTableRow key={report.id}>
                        <CTableDataCell>
                          <div className="fw-semibold">
                            {report.title || `Report #${report.id}`}
                          </div>
                          <div className="small text-body-secondary">
                            {report.categoryName || '-'}
                          </div>
                        </CTableDataCell>
                        <CTableDataCell>{report.citizenName || '-'}</CTableDataCell>
                        <CTableDataCell>
                          <StatusBadge type="report" value={report.status} />
                        </CTableDataCell>
                        <CTableDataCell>{formatDateTime(report.createdAt)}</CTableDataCell>
                      </CTableRow>
                    ))}
                  </CTableBody>
                </CTable>
              ) : (
                <EmptyState title="No recent reports" />
              )}
            </CCardBody>
          </CCard>
        </CCol>
      </CRow>
    </>
  )
}

export default Dashboard
