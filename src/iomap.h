//==============================================================================
// iomap.h
//==============================================================================
#ifndef __IOMAP_H__
#define __IOMAP_H__

uint32_t readIOmap (uint32_t addr);
void writeIOmap (uint32_t addr, uint32_t x);
void killHostIO(void);

#define BAD_IOADDR  -70
#define BAD_HOSTAPI -76

#endif // __IOMAP_H__
