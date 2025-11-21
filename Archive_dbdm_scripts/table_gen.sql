


CREATE TABLE `diseases` (
  `id` int NOT NULL,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `diseases_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `procedures` (
  `procedure_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` text,
  PRIMARY KEY (`procedure_id`),
  UNIQUE KEY `procedures_unique` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `mgi_genes` (
  `id` int NOT NULL,
  `symbol` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `omim_disease_link` (
  `id` int NOT NULL AUTO_INCREMENT,
  `disease_id` int NOT NULL,
  `omim_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `omim_disease_link_unique` (`disease_id`,`omim_id`),
  CONSTRAINT `omim_disease_link_diseases_FK` FOREIGN KEY (`disease_id`) REFERENCES `diseases` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2055 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `mouse_human_link` (
  `id` int NOT NULL AUTO_INCREMENT,
  `disease_id` int NOT NULL,
  `mgi_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mouse_human_link_unique` (`disease_id`,`mgi_id`),
  KEY `mouse_human_link_genes_FK` (`mgi_id`),
  CONSTRAINT `mouse_human_link_diseases_FK` FOREIGN KEY (`disease_id`) REFERENCES `diseases` (`id`),
  CONSTRAINT `mouse_human_link_genes_FK` FOREIGN KEY (`mgi_id`) REFERENCES `mgi_genes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4166 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `parameters` (
  `name` varchar(128) DEFAULT NULL,
  `description` text,
  `parameter_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `procedure_id` int NOT NULL,
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`parameter_id`),
  KEY `parameter_dataset_procedures_FK` (`procedure_id`),
  CONSTRAINT `parameter_dataset_procedures_FK` FOREIGN KEY (`procedure_id`) REFERENCES `procedures` (`procedure_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `impc_parameter_orig_id` (
  `id` int NOT NULL,
  `parameter_id` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `impc_parameter_orig_id_parameters_FK` (`parameter_id`),
  CONSTRAINT `impc_parameter_orig_id_parameters_FK` FOREIGN KEY (`parameter_id`) REFERENCES `parameters` (`parameter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `mouse_analysis` (
  `id` varchar(50) NOT NULL,
  `gene_id` int NOT NULL,
  `life_stage` varchar(50) NOT NULL,
  `strain` varchar(50) NOT NULL,
  `pvalue` double DEFAULT NULL,
  `parameter_id` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `mouse_analysis_mgi_genes_FK` (`gene_id`),
  KEY `mouse_analysis_parameter_FK` (`parameter_id`),
  CONSTRAINT `mouse_analysis_mgi_genes_FK` FOREIGN KEY (`gene_id`) REFERENCES `mgi_genes` (`id`),
  CONSTRAINT `mouse_analysis_parameter_FK` FOREIGN KEY (`parameter_id`) REFERENCES `parameters` (`parameter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



