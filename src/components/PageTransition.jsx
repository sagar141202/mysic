import { motion } from 'framer-motion'

export default function PageTransition({ children, pageKey }) {
  return (
    <motion.div
      key={pageKey}
      initial={{ opacity: 0, y: 16, scale: 0.99 }}
      animate={{ opacity: 1, y: 0,  scale: 1    }}
      exit={{    opacity: 0, y: -8, scale: 0.99 }}
      transition={{ duration: 0.28, ease: [0.25, 0.46, 0.45, 0.94] }}
      style={{ height: '100%' }}
    >
      {children}
    </motion.div>
  )
}
