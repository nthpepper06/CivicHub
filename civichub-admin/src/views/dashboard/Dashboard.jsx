import React, { useEffect, useMemo, useState } from 'react'
import {
  CBadge,
  CCard,
  CCardBody,
  CCardHeader,
  CCol,
  CRow,
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
  getRecentReports,
} from '../../api/dashboardService'
import { getApiErrorMessage } from '../../api/apiUtils'
import { EmptyState, ErrorAlert, LoadingState } from '../../components/admin/AdminPageState'
import { formatDateTime, formatLabel, reportStatusColor } from '../../utils/display'

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

const Dashboard = () => {
  const [summary, setSummary] = useState({})
  const [categories, setCategories] = useState([])
  const [departments, setDepartments] = useState([])
  const [monthly, setMonthly] = useState([])
  const [recentReports, setRecentReports] = useState([])
  const [loading, setLoading] = useState(true)
  const [sectionErrors, setSectionErrors] = useState({})

  useEffect(() => {
    const loadDashboard = async () => {
      setLoading(true)
      setSectionErrors({})

      const results = await Promise.allSettled([
        getDashboardSummary(),
        getCategoryStatistics(),
        getDepartmentStatistics(),
        getMonthlyStatistics(new Date().getFullYear()),
        getRecentReports(10),
      ])

      const [summaryResult, categoryResult, departmentResult, monthlyResult, recentResult] = results
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

      if (recentResult.status === 'fulfilled') {
        setRecentReports(recentResult.value.content)
      } else {
        setRecentReports([])
        nextErrors.recent = getApiErrorMessage(recentResult.reason)
      }

      setSectionErrors(nextErrors)
      setLoading(false)
    }

    const loadTimer = window.setTimeout(() => {
      loadDashboard()
    }, 0)

    return () => window.clearTimeout(loadTimer)
  }, [])

  const monthlyChart = useMemo(() => {
    const byMonth = new Map(monthly.map((item) => [item.month, item]))

    return monthLabels.map((_, index) => byMonth.get(index + 1) || {})
  }, [monthly])

  if (loading) {
    return <LoadingState label="Loading dashboard..." />
  }

  return (
    <>
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
              {recentReports.length ? (
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
                          <CBadge color={reportStatusColor(report.status)}>
                            {formatLabel(report.status)}
                          </CBadge>
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
