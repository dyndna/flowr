# flowr
Sahil Seth  
`r Sys.Date()`  




# Get started




```r
library(flowr)
```


```r
setup()
```
This will copy the flowr helper script to `~/bin`. Please make sure that this folder is in your `$PATH` variable. 
For more details refer to [setup's help section](http://docs.flowr.space/rd.html#setup).

<!---We have a quite handy command-line-interface for flowr, which exposes all functions of the package to terminal. Such that we dont have to open a interactive R session each time. To make this work, run a setup function which copies the 'flowr' helper script to your `~/bin` directory. ---> 

Running flowr from the terminal will fetch you the following:

```
Usage: flowr function [arguments]

status          Detailed status of a flow(s).
rerun           rerun a previously failed flow
kill            Kill the flow, upon providing working directory
fetch_pipes     Checking what modules and pipelines are available; flowr fetch_pipes

Please use 'flowr -h function' to obtain further information about the usage of a specific function.
```


<!--If you would like to do a test drive on its other capabilities, here are a [few examples](https://github.com/sahilseth/rfun).-->


## Toy example




![](files/toy.png)




Consider, a simple example where we have **three** instances of linux's `sleep` command. After its completion **three** tmp files are created with some random data. Then, a merging step follows, combining the tmp files into one big file. Next, we use `du` to calculate the size of the merged file.

<div class="alert alert-info" role="alert">
**NGS context** This is quite similar in structure to a typical workflow from where a series of alignment and sorting steps may take place on the raw fastq files. Followed by merging of the resulting bam files into one large file per-sample and further downstream processing.
</div>

To create this flow in flowr, we need the actual commands to run; and a set of instructions regarding how to stich the individual steps
into a coherent pipeline.

Here is a table with the commands we would like to run ( or `flow mat` ).


samplename   jobname      cmd                                                            
-----------  -----------  ---------------------------------------------------------------
sample1      sleep        sleep 10 && sleep 2;echo hello                                 
sample1      sleep        sleep 11 && sleep 8;echo hello                                 
sample1      sleep        sleep 11 && sleep 17;echo hello                                
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_1                    
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_2                    
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_3                    
sample1      merge        cat sample1_tmp_1 sample1_tmp_2 sample1_tmp_3 > sample1_merged 
sample1      size         du -sh sample1_merged; echo MY shell: $SHELL                   

Further, we use an additional file specifying the relationship between the steps, and also other resource requirements: [flow_def](http://docs.flowr.space/docs.html#flow-definition). 



jobname      sub_type   prev_jobs    dep_type   queue    memory_reserved  walltime    cpu_reserved  platform    jobid
-----------  ---------  -----------  ---------  ------  ----------------  ---------  -------------  ---------  ------
sleep        scatter    none         none       short               2000  1:00                   1  torque          1
create_tmp   scatter    sleep        serial     short               2000  1:00                   1  torque          2
merge        serial     create_tmp   gather     short               2000  1:00                   1  torque          3
size         serial     merge        serial     short               2000  1:00                   1  torque          4

<div class="alert alert-info" role="alert">
**Note:** Each row in a flow mat relates to one job. Jobname column is used to link flow definition with flow mat.
Also, values in previous jobs (prev_jobs) are derived from jobnames.
</div>

## Stitch it

We use the two files descirbed above and stich them to create a `flow object` (which contains all the information we
need for cluster submission). 



```r
ex = file.path(system.file(package = "flowr"), "pipelines")
flowmat = as.flowmat(file.path(ex, "sleep_pipe.tsv"))
flowdef = as.flowdef(file.path(ex, "sleep_pipe.def"))

fobj <- to_flow(x = flowmat, 
                 def = flowdef,
                 flowname = "example1", ## give it a name
                 platform = "lsf")      ## override platform mentioned in flow def
```

Refer to [to_flow's help section](docs.flowr.space/rd.html#to_flow) for more details.

## Plot it

We can use `plot_flow` to quickly visualize the flow; this really helps when developing complex workflows. 


```r
plot_flow(fobj)     # ?plot_flow for more information
plot_flow(flowdef) # plot_flow works on flow definition as well
```

![Flow chart describing process for example 1](flowr_overview_files/figure-html/plotit-1.png) 

Refer to [plot_flow's help section](docs.flowr.space/rd.html#plot_flow) for more details.


## Dry Run

<div class="alert alert-info" role="alert">
<b>Dry run</b>: Quickly perform a dry run, of the submission step. This creates all the folder and files, and skips submission 
to the cluster. This helps in debugging etc.
</div>


```r
submit_flow(fobj)
```

```
Test Successful!
You may check this folder for consistency. Also you may re-run submit with execute=TRUE
 ~/flowr/sleep_pipe-20150520-15-18-27-5mSd32G0
```

## Submit it

<div class="alert alert-info" role="alert">
Submit to the cluster !
</div>



```r
submit_flow(fobj, execute = TRUE)
```

```
Flow has been submitted. Track it from terminal using:
flowr status x=~/flowr/type1-20150520-15-18-46-sySOzZnE
```

Refer to [submit_flow's help section](docs.flowr.space/rd.html#submit_flow) for more details.


## Check its status

One may periodically run `status` to monitor the status of a flow.


```
flowr status x=~/flowr/runs/sleep_pipe-20150520*

|          | total| started| completed| exit_status|    status|
|:---------|-----:|-------:|---------:|-----------:|---------:|
|001.sleep |    10|      10|        10|           0| completed|
|002.tmp   |    10|      10|        10|           0| completed|
|003.merge |     1|       1|         1|           0| completed|
|004.size  |     1|       1|         1|           0| completed|
```

Alternatively, to check a summarized status of several flows, use the parent folder, for example:

```
flowr status x=~/flowr/runs

Showing status of: ~/flowr/runs
|          | total| started| completed| exit_status|    status|
|:---------|-----:|-------:|---------:|-----------:|---------:|
|001.sleep |    30|      30|        10|           0|processing|
|002.tmp   |    30|      30|        10|           0|processing|
|003.merge |     3|       3|         1|           0|   pending|
|004.size  |     3|       3|         1|           0|   pending|
```

<div class="alert alert-success" role="alert">
<b>Scalability</b>: Quickly submit, and check a summarized OR detailed status on ten or hundreds of 
flows.
</div>

Refer to [status's help section](docs.flowr.space/rd.html#status) for more details.


## Kill it

Incase something goes wrong, one may use to kill command to terminate all the relating jobs.


kill one flow:
```
flowr kill_flow x=flow_wd
```

<div class="alert alert-warning" role="alert">
One may instruct flowr to kill multiple flows,  but flowr would confirm before killing.
</div>

```
flowr kill x='~/flowr/runs/sleep_pipe'
found multiple wds:
  ~/flowr/runs/sleep_pipe-20150825-16-24-04-0Lv1PbpI
  ~/flowr/runs/sleep_pipe-20150825-17-47-52-5vFIkrMD
Really kill all of them ? kill again with force=TRUE
```

To kill multiple flow, set force=TRUE:

```
kill(x='~/flowr/runs/sleep_pipe*', force = TRUE)
```

Refer to [kill's help section](docs.flowr.space/rd.html#kill) for more details.


## Re-run a flow

flowr also enables you to re-run a pipeline in case of hardware or software failures.

- **hardware failure**: no change to the pipeline is required, simply rerun it: 
  `rerun(x=flow_wd, start_from=<intermediate step>)`
- **software failure**: either a change to flowmat or flowdef has been made: 
  `rerun(x=flow_wd, mat = new_flowmat, def = new_flowdef, start_from=<intermediate step>)`

Refer to [rerun's help section](docs.flowr.space/rd.html#rerun) for more details.




# Ingredients for building a pipeline

An easy and quick way to build a workflow is to create a set of two tab delimited files. First is a table with commands to run (for each step of the pipeline), while second has details regarding how the modules are stitched together. In the rest of this document we would refer to them as `flow_mat` and `flow_def` respectively (as introduced in the previous sections).

We could read in, examples of both these files to understand their structure.


```r
ex = file.path(system.file(package = "flowr"), "pipelines")
flow_mat = as.flowmat(file.path(ex, "sleep_pipe.tsv"))
flow_def = as.flowdef(file.path(ex, "sleep_pipe.def"))
```





## 1. Flow matrix

<div class="alert alert-info" role="alert">
describes commands to run:

Each row in flow mat describes one shell command, with additional information regarding the name of the step etc.
</div>


Essentially, this is a tab delimited file with three columns:

- `samplename`: A grouping column. The table is split using this column and each subset is treated as an individual flow. 
Thus we may have one flowmat for a series of samples, and the whole set would be submitted as a batch.
	- If all the commands are for a single sample, one can just repeat a dummy name like sample1 all throughout.
- `jobname`: This corresponds to the name of the step. This should match exactly with the jobname column in flow_def table described below.
- `cmd`: A shell command to run. One can get quite creative here. These could be multiple shell commands separated by a `;` or `&&`, more on this [here](http://stackoverflow.com/questions/3573742/difference-between-echo-hello-ls-vs-echo-hello-ls). Though to keep this clean you may just wrap a multi-line command into a script and just source the bash script from here.

Here is an example [flow_mat](https://github.com/sahilseth/flowr/blob/master/inst/pipelines/sleep_pipe.tsv) for the 
flowr described above.



samplename   jobname      cmd                                                            
-----------  -----------  ---------------------------------------------------------------
sample1      sleep        sleep 10 && sleep 2;echo hello                                 
sample1      sleep        sleep 11 && sleep 8;echo hello                                 
sample1      sleep        sleep 11 && sleep 17;echo hello                                
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_1                    
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_2                    
sample1      create_tmp   head -c 100000 /dev/urandom > sample1_tmp_3                    
sample1      merge        cat sample1_tmp_1 sample1_tmp_2 sample1_tmp_3 > sample1_merged 
sample1      size         du -sh sample1_merged; echo MY shell: $SHELL                   

## 2. Flow definition

<div class="alert alert-info" role="alert">
defines how to stich pieces of the (work)flow:

Each row in this table refers to one step of the pipeline. 
It describes the resources used by the step and also its relationship with other steps, especially, the step immediately prior to it.
</div>



It is a tab separated file, with a minimum of 4 columns:

- `jobname`: Name of the step
- `sub_type`: Short for [submission type](#submission-types), refers to, how should multiple commands of this step be submitted. Possible values are `serial` or `scatter`. 
- `prev_job`: Short for previous job, this would be jobname of the previous job. This can be NA/./none if this is a independent/initial step, and no previous step is required for this to start. 
- `dep_type`: Short for [dependency type](#dependency-types), refers to the relationship of this job with the one defined in `prev_job`. This can take values `none`, `gather`, `serial` or `burst`.

These would be explained in detail, below.

Apart from the above described variables, several others defining the resource requirements of each step are also available. These give great amount of flexibility to the user in choosing CPU, wall time, memory and queue for each step (and are passed along to the HPCC platform). 

- `cpu_reserved`
- `memory_reserved`
- `nodes`
- `walltime`
- `queue`

<div class="alert alert-info" role="alert">
This is especially useful for genomics pipelines, since each step may use different amount of resources. For example, in other frameworks, if one step uses 16 cores these would be blocked and not used during processing of several other steps. Thus resulting in blockage of those cores. Flowr prevents this, by being able to tune resources granurly. Example, one may submit few short steps in `short` queue, and longer steps of the same pipeline in say `long` queue.
</div>

Most cluster platforms accept these resource arguments. Essentially a file like [this](https://github.com/sahilseth/flowr/blob/master/inst/conf/torque.sh) is used as a template, and variables defined in curly braces ( ex. `{{{CPU}}}` ) are filled up using the flow definition file.

<div class="alert alert-success" role="alert">
If these (resource requirements) columns are not included in the flow definition, their values should be explicitly defined in the [submission template](https://github.com/sahilseth/flowr/blob/master/inst/conf).
One may customize the templates as described in the [cluster support](#cluster-support) section.
</div>


Here is an example of a typical [flow_def](https://raw.githubusercontent.com/sahilseth/flowr/master/inst/pipelines/sleep_pipe.def) file.



jobname      sub_type   prev_jobs    dep_type   queue    memory_reserved  walltime    cpu_reserved  platform    jobid
-----------  ---------  -----------  ---------  ------  ----------------  ---------  -------------  ---------  ------
sleep        scatter    none         none       short               2000  1:00                   1  torque          1
create_tmp   scatter    sleep        serial     short               2000  1:00                   1  torque          2
merge        serial     create_tmp   gather     short               2000  1:00                   1  torque          3
size         serial     merge        serial     short               2000  1:00                   1  torque          4


<!-- Each row of this table translates to a call to ([job](http://docs.flowr.space/build/html/rd/topics/job.html) or) [queue](http://docs.flowr.space/build/html/rd/topics/queue.html) function. -->

<!-- 
- jobname: is passed as `name` argument to job().
- prev_jobs: passed as `previous_job` argument  to job().
- dep_type: passed as `dependency_type` argument  to job(). Possible values: gather, serial
- sub_type: passed as `submission_type` argument  to job().
- queue: name of the queue to be used for this particular job. 
	Since each jobs can be submitted to a different queue, this makes your flow very flexible
- memory_reserved: Refer to your system admin guide on what values should go here. 
	Some pipelines: 160000, 16g etc representing a 16GB reservation of RAM
- walltime: How long would this job run. Again refer to your HPCC guide. Example: 24:00, 24:00:00
- cpu_reserved: Amount of CPU reserved.

Its best to have this as a tab seperated file (with no row.names). -->

<!---
### Style 2

This style may be more suited for people who like to explore more advanced usage and like to code in R. Also this one find this much faster if jobs and their relationships changes a lot.

Here instead of seperating cmds and definitions one defines them step by step incrementally.

- Use: queue(), to define the computing cluster being used
- Use: multiple calls job()
- Use: flow() to stich the jobs into a flow.


Currently we support LSF, Torque and SGE. Let us use LSF for this example.


```r
qobj <- queue(platform = "lsf", queue = "normal", verbose = FALSE)
```

Let us stitch a simple flow with three jobs, which are submitted one after the other.


```r
job1 <- job(name = "myjob1", cmds = "sleep1", q_obj = qobj)
job2 <- job(name = "myjob2", cmds = "sleep2", q_obj = qobj, previous_job = "myjob1", dependency_type = "serial")
job3 <- job(name = "myjob3", cmds = "sleep3", q_obj = qobj, previous_job = "myjob1", dependency_type = "serial")
fobj <- flow(name = "myflow", jobs = list(job1, job2, job3), desc="description")
plot_flow(fobj)
```

The above translates to a flow definition which looks like this:


```r
dat <- flowr:::create_jobs_mat(fobj)
knitr:::kable(dat)
```
--->



### Example:

Let us use an example flow, to understand submission and dependency types.

Consider three steps A, B and C, where A has 10 commands from A1 to A10, similarly B has 10 commands B1 through B10 and C has a single command, C1. Consider another step D (with D1-D3), which comes after C.

```
step:       A   ----> B  -----> C -----> D
# of cmds  10        10         1        3
```

# Submission types


*This refers to the sub_type column in flow definition.*

- `scatter`: submit all commands as parallel, independent jobs. 
	- *Submit A1 through A10 as independent jobs*
- `serial`: run these commands sequentially one after the other. 
	- *Wrap A1 through A10, into a single job.*

# Dependency types

*This refers to the dep_type column in flow definition.*

- `none`: independent job. 
	- *Initial step A has no dependency*
- `serial`: *one to one* relationship with previous job. 
	- *B1 can start as soon as A1 completes.*
- `gather`: *many to one*, wait for **all** commands in previous job to finish then start the  current step. 
	- *All jobs of B (1-10), need to complete before C1 is started*
- `burst`: *one to many* wait for the previous step which has one job and start processing all cmds in the current step. 
	- *D1 to D3 are started as soon as C1 finishes.*


# Relationships

Using the above submission and dependency types one can create several types of relationships between former and later jobs. Here are a few examples of relationships one may typically use.


## One to One (serial)


```
                A1 --------> B1
                A2 --------> B1
                .. --------> ..
               A10 --------> B10
 dependency submission  dependency submission   
    none     scatter      serial     scatter
                 relationship
                  ONE-to-ONE
```

Relationship between steps A and B is best defined as `serial`. Step A (A1 through A10) is submitted as scatter. Further, $i^th$ jobs of B depends on $i^th$ jobs of A. i.e. B1 requires A1 to complete; B2 requires A2 and so on. Also, we note that defining dependency as serial, makes sure that B does not wait for all elements of A to complete.



![](flowr_overview_files/figure-html/plot_one_one-1.png) 

## Many to One (gather)

```
                B1 ----\ 
                B2 -----\
                ..        -----> C1
                B9 ------/
                B10-----/
 dependency submission  dependency submission   
    serial     scatter    gather     serial
                 relationship
                  MANY-to-ONE
```


Since C is a single command which requires all steps of B to complete, intuitively it needs to `gather` pieces of data generated by B. In this case `dep_type` would be `gather` and `sub_type` type would be `serial` since it is a single command.



<!---
- makes sense when previous job had many commands running in parallel and current job would wait for all
- so previous job submission: `scatter`, and current job's dependency type `gather`

--->

## One to Many (Burst)

```
                     /-----> D1
                C1 --------> D2
                     \-----> D3
 dependency submission  dependency submission   
    gather   serial       burst     scatter
                 relationship
                  ONE-to-MANY
```

Further, D is a set of three commands (D1-D3), which need to wait for a single process (C1) to complete. They would be submitted as `scatter` after waiting on C in a `burst` type dependency.




<!---
- makes sense when previous job had one command current job would split and submit several jobs in parallel
- so previous job submission_type: `serial`, and current job's dependency type `burst`, with a submission type: `scatter`

--->

In essence, an example flow_def would look like as follows (with additional resource requirements not shown for brevity):



```r
ex2def = as.flowdef(file.path(ex, "abcd.def"))
ex2mat = as.flowmat(file.path(ex, "abcd.tsv"))
kable(ex2def[, 1:4])
```



jobname   sub_type   prev_jobs   dep_type 
--------  ---------  ----------  ---------
A         scatter    none        none     
B         scatter    A           serial   
C         serial     B           gather   
D         scatter    C           burst    

```r
plot_flow(ex2def)
```

![](flowr_overview_files/figure-html/plot_abcd-1.png) 

<div class="alert alert-info" role="alert">
There is a darker more prominent shadow to indicate 
scatter steps.
</div>









# Cluster Support

As of now we have tested this on the following clusters:


Platform   command   status   queue.type 
---------  --------  -------  -----------
LSF 7      bsub      Beta     lsf        
LSF 9.1    bsub      Stable   lsf        
Torque     qsub      Stable   torque     
Moab       msub      Stable   moab       
SGE        qsub      Beta     sge        
SLURM      sbatch    alpha    slurm      


For more details, refer to the [configuration section](http://docs.flowr.space/install.html#cluster)

<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-68378910-1', 'auto');
  ga('send', 'pageview');

</script>