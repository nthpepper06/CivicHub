import React from 'react'
import { CFooter } from '@coreui/react'

const AppFooter = () => {
  return (
    <CFooter className="px-4">
      <div>
        <span className="fw-semibold">CivicHub Admin</span>
        <span className="ms-1">&copy; 2026 CivicHub.</span>
      </div>
      <div className="ms-auto">
        <span className="text-body-secondary">Operational console</span>
      </div>
    </CFooter>
  )
}

export default React.memo(AppFooter)
