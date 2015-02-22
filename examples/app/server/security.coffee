roles.permit(['insert', 'update', 'remove']).never().apply()
post.permit('insert').ifHasRoleE('clinical').apply()
