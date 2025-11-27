-- SQL file for qb-inventory stash storage
-- Run this in your database to create the stash items table

CREATE TABLE IF NOT EXISTS `stashitems` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `stash` VARCHAR(255) NOT NULL,
    `items` LONGTEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `stash` (`stash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
