#ifndef __YAPL_H__
#define __YAPL_H__

#include "parser.tab.h"

#ifdef YAPL_DEBUG
#define ASSERT(cond, fmt, args...)	do {									\
	if (!(cond)) {															\
		fprintf(stderr, "%s:%d -- " fmt "\n", __func__, __LINE__, ##args);	\
		exit(1);															\
	}																		\
} while (0)
#else
#define ASSERT(cond, fmt, args...)
#endif

#ifdef YAPL_DEBUG
#define DPRINTF(fmt, args...) printf("%s: " fmt, __func__, ##args)
#else
#define DPRINTF(fmt, args...)
#endif

enum data_size {
	BYTE,
	WORD,
	DWORD,
	QWORD
};

#endif /* __YAPL_H__ */
