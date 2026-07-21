import React from 'react'
import PropTypes from 'prop-types'
import { CToast, CToastBody, CToastClose, CToaster } from '@coreui/react'

const AdminToast = ({ message, color = 'success', onClose }) => (
  <CToaster placement="top-end" className="p-3">
    {message && (
      <CToast visible autohide delay={3500} color={color} onClose={onClose}>
        <div className="d-flex">
          <CToastBody>{message}</CToastBody>
          <CToastClose className="me-2 m-auto" white={color !== 'light'} onClick={onClose} />
        </div>
      </CToast>
    )}
  </CToaster>
)

AdminToast.propTypes = {
  message: PropTypes.string,
  color: PropTypes.string,
  onClose: PropTypes.func.isRequired,
}

export default AdminToast
