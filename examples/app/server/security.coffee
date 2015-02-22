post.permit('insert').ifHasRoleE('clinical').apply()
roles.permit(['insert', 'update', 'remove']).never().apply()