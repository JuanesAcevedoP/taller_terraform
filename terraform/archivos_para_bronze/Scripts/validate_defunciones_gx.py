import sys
import json
from datetime import datetime
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions

import great_expectations as gx

# -----------------------------------
# 🔧 Inicializar Glue
# -----------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# -----------------------------------
# 📂 Leer datos desde Bronze (S3)
# -----------------------------------
input_path = "s3://datalake-bronze-941508878188/defunciones/"

df = spark.read \
    .option("header", True) \
    .option("encoding", "UTF-8") \
    .csv(input_path)

# Renombrar columnas con espacios para evitar conflictos
df = df.withColumnRenamed("NOM_6 67_OPS_GRUPO", "NOM_OPS_GRUPO") \
       .withColumnRenamed("NOM_6 67_OPS_SUBC", "NOM_OPS_SUBC")

# -----------------------------------
# 🔍 Inicializar Great Expectations
# -----------------------------------
context = gx.get_context()

data_source = context.sources.add_or_update_spark(name="spark_source")
data_asset = data_source.add_dataframe_asset(name="defunciones_data")

batch_request = data_asset.build_batch_request(dataframe=df)

# -----------------------------------
# 📋 Expectation Suite
# -----------------------------------
suite = context.add_or_update_expectation_suite("suite_defunciones")

validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite=suite
)

# ============================================================
# ✅ LAS 10 VALIDACIONES / EXPECTATIVAS
# ============================================================
validator.expect_table_row_count_to_be_between(min_value=10000)

expected_columns = [
    "NUM_FORMUL", "COD_INST", "NOM_INST", "TIPO_DEFUN", "FECHA_DEF",
    "ANO", "MES", "SEXO", "EST_CIVIL", "EDAD", "NIVEL_EDU", "CODPTORE",
    "CODMUNRE", "COD_BARRIRES", "SEG_SOCIAL", "IDADMISALU", "IDCODADMI",
    "IDCLASADMI", "N_BAS1", "C_BAS1", "BARRIO_RES", "COMUNA_RES",
    "ETAREO_QUIN", "EDAD_SIMPLE", "NOM_OPS_GRUPO", "NOM_OPS_SUBC"
]
validator.expect_table_columns_to_match_ordered_list(expected_columns)

validator.expect_column_values_to_not_be_null("NUM_FORMUL")
validator.expect_column_values_to_not_be_null("FECHA_DEF", mostly=0.99)
validator.expect_column_values_to_be_between("ANO", 2010, 2024, mostly=0.99)
validator.expect_column_values_to_be_between("MES", 1, 12, mostly=0.99)
validator.expect_column_values_to_be_in_set("SEXO", ["1", "2"], mostly=0.98)
validator.expect_column_values_to_be_between("EDAD_SIMPLE", 0, 110, mostly=0.97)
validator.expect_column_values_to_not_be_null("NOM_OPS_GRUPO", mostly=0.98)
validator.expect_column_values_to_not_be_null("COMUNA_RES", mostly=0.95)

# ============================================================
# 🚀 Ejecutar todas las validaciones
# ============================================================
results = validator.validate()

print("===== RESULTADOS GX =====")
print(results)

# ============================================================
# 💾 Guardar resultados en S3 Silver como JSON
# ============================================================
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_path = f"s3://datalake-silver-941508878188/defunciones/validations/validacion_{timestamp}"

# Convertir resultados a JSON serializable
results_json = results.to_json_dict()
json_str = json.dumps(results_json, indent=2, ensure_ascii=False)

# Crear DataFrame con el JSON
json_df = spark.createDataFrame([(json_str,)], ["gx_results"])

# Guardar en S3 (Silver)
json_df.coalesce(1).write.mode("overwrite").text(output_path)

print(f"Resultados guardados en: {output_path}")

# ============================================================
# 🛑 Control de fallo — detiene el pipeline en Step Function
# ============================================================
if not results["success"]:
    raise Exception(
        f"[GREAT EXPECTATIONS] Data Quality FAILED. "
        f"Resultados guardados en: {output_path}. "
        f"El pipeline se detiene para proteger Silver y Gold."
    )

print("✅ Todas las validaciones pasaron. El pipeline puede continuar.")