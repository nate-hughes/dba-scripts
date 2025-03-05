
SELECT	@@SERVERNAME AS ServerName
		,DEFAULT_DOMAIN() AS Domain
		,p.name AS PrincipalName
		,p.is_disabled AS IsPrincipalDisabled
		,r.name AS RoleName
		,r.is_fixed_role AS IsFixedRole
		,r.is_disabled AS IsRoleDisabled
FROM	sys.server_role_members srm
        INNER JOIN (
			SELECT  principal_id
					,name
					,is_disabled
					,is_fixed_role
			FROM    sys.server_principals
			WHERE   type_desc = 'SERVER_ROLE'
        ) r ON r.principal_id = srm.role_principal_id
        RIGHT JOIN sys.server_principals p ON p.principal_id = srm.member_principal_id
WHERE   p.type_desc NOT IN ('SERVER_ROLE')
AND		r.name IS NOT NULL;
