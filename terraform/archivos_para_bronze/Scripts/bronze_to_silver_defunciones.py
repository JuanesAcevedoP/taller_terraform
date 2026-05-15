import sys
from pyspark.context import SparkContext
from pyspark.sql.functions import col, when
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
args = getResolvedOptions(sys.argv, [])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
input_path = "s3://datalake-bronze-941508878188/defunciones/"
output_path = "s3://datalake-silver-941508878188/defunciones/"
df = spark.read.option("header", True).option("encoding", "UTF-8").csv(input_path)
df = df.withColumnRenamed("NOM_6 67_OPS_GRUPO", "NOM_OPS_GRUPO") \
       .withColumnRenamed("NOM_6 67_OPS_SUBC", "NOM_OPS_SUBC")
df = df.withColumn("ANO", col("ANO").cast("integer")) \
       .withColumn("MES", col("MES").cast("integer")) \
       .withColumn("SEXO", col("SEXO").cast("integer")) \
       .withColumn("EDAD_SIMPLE", col("EDAD_SIMPLE").cast("integer")) \
       .withColumn("IDADMISALU", col("IDADMISALU").cast("double"))
df = df.withColumn("EDAD_SIMPLE",
    when((col("EDAD_SIMPLE") < 0) | (col("EDAD_SIMPLE") > 110), None)
    .otherwise(col("EDAD_SIMPLE"))
)
df = df.withColumn("NOM_INST",
    when(col("NOM_INST") == "", None).otherwise(col("NOM_INST"))
).withColumn("IDCODADMI",
    when(col("IDCODADMI") == "", None).otherwise(col("IDCODADMI"))
).withColumn("IDCLASADMI",
    when(col("IDCLASADMI") == "", None).otherwise(col("IDCLASADMI"))
)
df = df.dropDuplicates(["NUM_FORMUL"])
df = df.dropna(subset=["NUM_FORMUL", "FECHA_DEF", "ANO", "MES", "SEXO"])
df.write.mode("overwrite").parquet(output_path)
print("Job Bronze -> Silver completado exitosamente")