USE <target-schema>;

DELIMITER //

CREATE PROCEDURE <procedure-name> ()
BEGIN
	SELECT	<column-list>
    FROM	<table>;
END //

DELIMITER ;
