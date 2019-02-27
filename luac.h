#ifndef __LUAC_H__
#define __LUAC_H__

#include "parser.tab.h"

#ifdef LUAC_DEBUG
#define ASSERT(cond, fmt, args...)	do {									\
	if (!(cond)) {															\
		fprintf(stderr, "%s:%d -- " fmt "\n", __func__, __LINE__, ##args);	\
		exit(1);															\
	}																		\
} while (0)
#else
#define ASSERT(cond, fmt, args...)
#endif

#ifdef LUAC_DEBUG
#define DPRINTF(fmt, args...) printf("%s: " fmt, __func__, ##args)
#else
#define DPRINTF(fmt, args...)
#endif

#endif /* __LUAC_H__ */
