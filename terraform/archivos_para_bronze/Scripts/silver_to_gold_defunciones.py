import sys
from pyspark.context import SparkContext
from pyspark.sql.functions import col, count, when
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
args = getResolvedOptions(sys.argv, [])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
input_path = "s3://datalake-silver-941508878188/defunciones/"
df = spark.read.parquet(input_path)
df_por_comuna = df.groupBy("COMUNA_RES", "ANO") \
    .agg(count("*").alias("TOTAL_MUERTES")) \
    .orderBy("ANO", "TOTAL_MUERTES", ascending=[True, False])
df_por_comuna.write.mode("overwrite").parquet(
    "s3://datalake-gold-941508878188/muertes_por_comuna/"
)
df_por_causa = df.groupBy("NOM_OPS_GRUPO", "SEXO") \
    .agg(count("*").alias("TOTAL_MUERTES")) \
    .withColumn("SEXO_DESC",
        when(col("SEXO") == 1, "Masculino")
        .when(col("SEXO") == 2, "Femenino")
        .otherwise("No especificado")
    ) \
    .orderBy("TOTAL_MUERTES", ascending=False)
df_por_causa.write.mode("overwrite").parquet(
    "s3://datalake-gold-941508878188/defunciones_metrics/"
)
print("Job Silver -> Gold completado exitosamente")