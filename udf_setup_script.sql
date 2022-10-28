put 'file://artifacts/java/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar' @~ auto_compress=false OVERWRITE=true;

create or replace function hllpp_count_strings_sketch(x string)
returns table(sketch binary)
language java
imports = ('@~/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar')
handler='com.lariat.agentudfs.HLPPCountStringsSketch';

create or replace function hll_merge(x array)
returns binary
language java
imports = ('@~/agent-udfs-0.1-SNAPSHOT-jar-with-dependencies.jar')
handler='com.lariat.agentudfs.HLPPMerge.merge';
