import React from 'react'
import PropTypes from 'prop-types'
import {
  CAlert,
  CBadge,
  CButton,
  CCard,
  CCardBody,
  CCol,
  CFormInput,
  CInputGroup,
  CModal,
  CModalBody,
  CModalFooter,
  CModalHeader,
  CModalTitle,
  CPagination,
  CPaginationItem,
  CSpinner,
} from '@coreui/react'
import CIcon from '@coreui/icons-react'
import { cilSearch } from '@coreui/icons'

import { booleanStatusColor, formatLabel, reportStatusColor } from '../../utils/display'

export const LoadingState = ({ label = 'Loading...' }) => (
  <div className="py-5 text-center">
    <CSpinner color="primary" className="mb-3" />
    <div className="text-body-secondary">{label}</div>
  </div>
)

LoadingState.propTypes = {
  label: PropTypes.string,
}

export const ErrorAlert = ({ message }) =>
  message ? (
    <CAlert color="danger" className="mb-4">
      {message}
    </CAlert>
  ) : null

ErrorAlert.propTypes = {
  message: PropTypes.string,
}

export const ErrorState = ErrorAlert

export const EmptyState = ({ title, description }) => (
  <div className="py-5 text-center text-body-secondary">
    <div className="fw-semibold text-body mb-1">{title}</div>
    {description && <div>{description}</div>}
  </div>
)

EmptyState.propTypes = {
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
}

export const LoadingSkeleton = ({ rows = 4 }) => (
  <div aria-label="Loading content">
    {Array.from({ length: rows }, (_, index) => (
      <div className="placeholder-glow mb-3" key={index}>
        <span className="placeholder col-12 mb-2"></span>
        <span className="placeholder col-8"></span>
      </div>
    ))}
  </div>
)

LoadingSkeleton.propTypes = {
  rows: PropTypes.number,
}

export const StatusBadge = ({ value, type = 'generic' }) => {
  const color =
    type === 'report'
      ? reportStatusColor(value)
      : type === 'active'
        ? booleanStatusColor(value)
        : 'secondary'
  const label = type === 'active' ? (value ? 'Active' : 'Inactive') : formatLabel(value)

  return <CBadge color={color}>{label}</CBadge>
}

StatusBadge.propTypes = {
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),
  type: PropTypes.oneOf(['generic', 'report', 'active']),
}

export const SearchToolbar = ({ value, onChange, placeholder = 'Search', children }) => (
  <div className="d-flex flex-wrap gap-2 mb-3 align-items-center">
    <CInputGroup className="flex-grow-1" style={{ minWidth: 240 }}>
      <span className="input-group-text">
        <CIcon icon={cilSearch} />
      </span>
      <CFormInput
        value={value}
        placeholder={placeholder}
        aria-label={placeholder}
        onChange={(event) => onChange(event.target.value)}
      />
    </CInputGroup>
    {children}
  </div>
)

SearchToolbar.propTypes = {
  value: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  placeholder: PropTypes.string,
  children: PropTypes.node,
}

export const FilterBar = ({ children }) => (
  <CCard className="mb-4">
    <CCardBody>
      <CCol xs={12} className="d-flex flex-wrap gap-2">
        {children}
      </CCol>
    </CCardBody>
  </CCard>
)

FilterBar.propTypes = {
  children: PropTypes.node.isRequired,
}

export const ConfirmModal = ({
  visible,
  title,
  message,
  confirmLabel = 'Confirm',
  confirmColor = 'danger',
  loading = false,
  onCancel,
  onConfirm,
}) => (
  <CModal visible={visible} onClose={onCancel} alignment="center">
    <CModalHeader>
      <CModalTitle>{title}</CModalTitle>
    </CModalHeader>
    <CModalBody>{message}</CModalBody>
    <CModalFooter>
      <CButton color="secondary" variant="outline" onClick={onCancel} disabled={loading}>
        Cancel
      </CButton>
      <CButton color={confirmColor} onClick={onConfirm} disabled={loading}>
        {loading && <CSpinner component="span" size="sm" className="me-2" />}
        {confirmLabel}
      </CButton>
    </CModalFooter>
  </CModal>
)

ConfirmModal.propTypes = {
  visible: PropTypes.bool.isRequired,
  title: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  confirmLabel: PropTypes.string,
  confirmColor: PropTypes.string,
  loading: PropTypes.bool,
  onCancel: PropTypes.func.isRequired,
  onConfirm: PropTypes.func.isRequired,
}

export const ConfirmDialog = ConfirmModal

export const PagePagination = ({ page, totalPages, onChange }) => {
  if (!totalPages || totalPages <= 1) {
    return null
  }

  const visiblePages = Array.from(
    new Set([
      0,
      Math.max(0, page - 2),
      Math.max(0, page - 1),
      page,
      Math.min(totalPages - 1, page + 1),
      Math.min(totalPages - 1, page + 2),
      totalPages - 1,
    ]),
  ).sort((first, second) => first - second)

  return (
    <CPagination align="end" className="mt-3 mb-0">
      <CPaginationItem disabled={page <= 0} onClick={() => onChange(page - 1)}>
        Previous
      </CPaginationItem>
      {visiblePages.map((item, index) => (
        <React.Fragment key={item}>
          {index > 0 && item - visiblePages[index - 1] > 1 && (
            <CPaginationItem disabled>...</CPaginationItem>
          )}
          <CPaginationItem active={item === page} onClick={() => onChange(item)}>
            {item + 1}
          </CPaginationItem>
        </React.Fragment>
      ))}
      <CPaginationItem disabled={page >= totalPages - 1} onClick={() => onChange(page + 1)}>
        Next
      </CPaginationItem>
    </CPagination>
  )
}

PagePagination.propTypes = {
  page: PropTypes.number.isRequired,
  totalPages: PropTypes.number.isRequired,
  onChange: PropTypes.func.isRequired,
}
