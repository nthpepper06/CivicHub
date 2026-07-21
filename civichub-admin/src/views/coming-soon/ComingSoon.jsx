import React from 'react'
import { CCard, CCardBody } from '@coreui/react'

const ComingSoon = () => {
  return (
    <CCard>
      <CCardBody>
        <h2 className="h4 mb-2">Coming Soon</h2>
        <p className="text-body-secondary mb-0">
          This admin module will be available in a later sprint.
        </p>
      </CCardBody>
    </CCard>
  )
}

export default ComingSoon
