USE communication;

DROP FUNCTION IF EXISTS process_batch_rows;   
DELIMITER //    
CREATE FUNCTION process_batch_rows() RETURNS VARCHAR(10) DETERMINISTIC
BEGIN
  DECLARE processed INT DEFAULT 0;
  DECLARE eachbatch INT DEFAULT 1000;
  DECLARE delete_row_count INT DEFAULT 0;

  my_loop: WHILE processed < 23000000
  DO
    DELETE
	FROM communication.cns_notifications
	WHERE processing_version_number = 'FIRST_VERSION'
    LIMIT eachbatch;

	SET delete_row_count = ROW_COUNT();
    
    IF delete_row_count < 1 THEN
        LEAVE my_loop;
    END IF;

    SET processed = processed + delete_row_count;
  END WHILE my_loop;    

  RETURN processed;
END //    
DELIMITER ;

SELECT process_batch_rows();

DROP FUNCTION IF EXISTS process_batch_rows;   