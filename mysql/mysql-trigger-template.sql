USE <target-schema>;

DELIMITER //

CREATE TRIGGER <trigger-name>
AFTER INSERT
ON <table> FOR EACH ROW
BEGIN
	UPDATE	<table>
    SET		<column> = <some-value>
    WHERE	<id-column> = NEW.<id-column>
END;

DELIMITER ;
