SELECT
  d.ID,
  d.AMOUNT,
  c.COMPANY_NAME
FROM `${projectid}.${datasetname}.DATASET2_MAIN` d
LEFT JOIN `${projectid}.${aptdatasetname}.PRC_APT_L1_COMPANY1` c
  ON d.COMPANY_ID = c.COMPANY_ID
