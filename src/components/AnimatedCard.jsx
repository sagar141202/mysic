import { motion } from 'framer-motion';

export default function AnimatedCard({ children, className = '', delay = 0, ...props }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      transition={{ duration: 0.35, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      whileHover={{ scale: 1.015, transition: { duration: 0.18 } }}
      {...props}
    >
      {children}
    </motion.div>
  );
}
