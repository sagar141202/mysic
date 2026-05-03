import { motion } from 'framer-motion'

export default function AnimatedCard({ children, className = '', style = {}, delay = 0, onClick, ...props }) {
  return (
    <motion.div
      className={className}
      style={style}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0  }}
      exit={{    opacity: 0, y: -10 }}
      transition={{ duration: 0.32, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      whileHover={{ scale: 1.018, transition: { duration: 0.16 } }}
      whileTap={{  scale: 0.97,  transition: { duration: 0.10 } }}
      onClick={onClick}
      {...props}
    >
      {children}
    </motion.div>
  )
}
