

#' @rdname as.flowmat
#' @title flow mat
#'
#' @description
#' as.flowmat(): reads a file and checks for required columns. If x is data.frame checks for required columns.
#'
#' @param x a data.frame or path to file with flow details in it.
#' @param grp_col column used for grouping, default samplename.
#' @param jobname_col column specifying jobname, default jobname
#' @param cmd_col column specifying commands to run, default cmd
#' @param ... not used
#'
#' @export
as.flowmat <- function(x, grp_col, jobname_col, cmd_col, ...){
	## ---- assuming x is a file

	if(is.flowmat(x))
		return(check(x))

	if(is.data.frame(x)){
		## prevent issues with factors
		x[] <- lapply(x, as.character)
	}

	if(is.character(x)){
		if(!file.exists(x))
			stop("file does not exists: ", x)
		message("mat seems to be a file, reading it...")
		x <- read_sheet(x, id_column = "jobname")
	}

	if(missing(grp_col)){
		grp_col = "samplename"
		if(grp_col %in% colnames(x))
			message("Using `", grp_col, "` as the grouping column")
		else
			stop("grouping column not specified, and the default 'samplename' is absent in the input x.")
	}
	if(missing(jobname_col)){
		jobname_col = "jobname"
		if(jobname_col %in% colnames(x))
			message("Using `", jobname_col, "` as the jobname column")
		else
			stop("jobname column not specified, and the default 'jobname' is absent in the input x.")
	}
	if(missing(cmd_col)){
		cmd_col = "cmd"
		if(cmd_col %in% colnames(x))
			message("Using `", cmd_col, "` as the cmd column")
		else
			stop("cmd column not specified, and the default 'cmd' is absent in the input x.")
	}

	## check col are single length column
	assert_character(grp_col, 1)
	assert_character(jobname_col, 1)
	assert_character(cmd_col, 1)

	## ---- renaming columns to make it easier for subsequent.
	x[, "jobname"] = x[, jobname_col]
	x[, "cmd"] = x[, cmd_col]
	x[, "samplename"] = x[, grp_col]

	## --- add class flowmat, suggests that this has been checked
	class(x) <- c("flowmat", "data.frame")
	x = check(x)
	return(x)
}


#' @rdname as.flowmat
#' @export
is.flowmat <- function(x){
	class(x)[1] == "flowmat"
}



#' @rdname to_flowmat
#'
#' @title Taking in a named list and returns a two columns data.frame
#'
#' @param x a named list OR vector. Where name corresponds to the jobname and value is a vector of commands to run
#' @param samplename character of length 1 or that of nrow(x)
#' @param ... not used
#'
#' @export
to_flowmat <- function(x, ...) {
	UseMethod("to_flowmat")
}


#' @rdname to_flowmat
#' @export
to_flowmat.list <- function(x, samplename, ...){
	if(missing(samplename))
		stop("to_flowmat needs a samplename !")

	if(is.null(names(x)))
		stop("supply a named object to to_flowmat")

	ret <- lapply(1:length(x), function(i){
		cmd = x[[i]]
		jobname = names(x[i])
		data.frame(jobname, cmd, stringsAsFactors = FALSE)
	})
	ret = do.call(rbind, ret)
	ret = cbind(samplename = samplename, ret)
	attr(ret, "class") <- c("flowmat", "data.frame")
	return(ret)

}

#' @rdname to_flowmat
#' @export
to_flowmat.data.frame <- function(x, ...){
	attr(x, "class") <- c("flowmat", "data.frame")
	message("Looks good, just check...")
	return(x)
}


#' @rdname to_flowmat
#' @export
to_flowmat.flow <- function(x, ...){
	## -- get all the commands as rows
	lst = lapply(x@jobs, function(y){
		cmd = list(y@cmds)
		names(cmd) = y@name
		to_flowmat(x = cmd, samplename = x@desc)
	})
	mat = do.call(rbind, lst)
	return(mat)
}


## --------------------- d e p r e c i a t e d        f u n c t i o n s ----------------------------- ##

## not used, use char instead
to_flowmat.character <- function(x, ...){
	.Deprecated("to_flowmat.list", msg = "Supply a named list instead of a vector.")
	ret <- lapply(1:length(x), function(i){
		cmd = x[i]
		jobname = names(x[i])
		data.frame(jobname, cmd, stringsAsFactors = FALSE)
	})
	do.call(rbind, ret)
}