SELECT
  c.COMPANY_NAME,
  d.AMOUNT,
  d.ID
FROM `${projectid}.${aptdatasetname}.PRC_APT_L1_COMPANY` c
JOIN `${projectid}.${dataset2datasetname}.DATASET2_MAIN` d
  ON c.COMPANY_ID = d.COMPANY_ID
