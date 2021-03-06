#' @rdname margins
#' @name margins
#' @aliases margins-package
#' @docType package
#' @title Marginal Effects Estimation
#' @description This package is an R port of Stata's \samp{margins} command, implemented as an S3 generic \code{margins()} for model objects, like those of class \dQuote{lm} and \dQuote{glm}. \code{margins()} is an S3 generic function for building a \dQuote{margins} object from a model object. Methods are currently implemented for \dQuote{lm} (and, implicitly, \dQuote{glm}) class objects and support is expanding. See Details, below.
#' 
#' The package also provides a low-level function, \code{\link{marginal_effects}}, to estimate those quantities and return a data frame of unit-specific effects and another, \code{\link{dydx}}, to provide variable-specific derivatives from models. Some of the underlying architecture for the package is provided by the low-level function \code{\link[prediction]{prediction}}, which provides a consistent data frame interface to \code{\link[stats]{predict}} for a large number of model types.
#' @param model A model object. See Details for supported model classes.
#' @param data A data frame containing the data at which to evaluate the marginal effects, as in \code{\link[stats]{predict}}. This is optional, but may be required when the underlying modelling function sets \code{model = FALSE}.
#' @param design Only for models estimated using \code{\link[survey]{svyglm}}, the \dQuote{survey.design} object used to estimate the model. This is required.
#' @param variables A character vector with the names of variables for which to compute the marginal effects. The default (\code{NULL}) returns marginal effects for all variables.
#' @param at A list of one or more named vectors, specifically values at which to calculate the marginal effects. This is an analogue of Stata's \code{, at()} option. The specified values are fully combined (i.e., a cartesian product) to find AMEs for all combinations of specified variable values. Rather than a list, this can also be a data frame of combination levels if only a subset of combinations are desired. These are used to modify the value of \code{data} when calculating AMEs across specified values (see \code{\link[prediction]{build_datalist}} for details on use). Note: This does not calculate AMEs for \emph{subgroups} but rather for counterfactual datasets where all observaations take the specified values; to obtain subgroup effects, subset \code{data} directly.
#' @param type A character string indicating the type of marginal effects to estimate. Mostly relevant for non-linear models, where the reasonable options are \dQuote{response} (the default) or \dQuote{link} (i.e., on the scale of the linear predictor in a GLM).
#' @param vcov A matrix containing the variance-covariance matrix for estimated model coefficients, or a function to perform the estimation with \code{model} as its only argument.
#' @param vce A character string indicating the type of estimation procedure to use for estimating variances. The default (\dQuote{delta}) uses the delta method. Alternatives are \dQuote{bootstrap}, which uses bootstrap estimation, or \dQuote{simulation}, which averages across simulations drawn from the joint sampling distribution of model coefficients. The latter two are extremely time intensive.
#' @param iterations If \code{vce = "bootstrap"}, the number of bootstrap iterations. If \code{vce = "simulation"}, the number of simulated effects to draw. Ignored otherwise.
#' @param unit_ses If \code{vce = "delta"}, a logical specifying whether to calculate and return unit-specific marginal effect variances. This calculation is time consuming and the information is often not needed, so this is set to \code{FALSE} by default.
#' @param eps A numeric value specifying the \dQuote{step} to use when calculating numerical derivatives.
#' @param \dots Arguments passed to methods, and onward to \code{\link{dydx}} methods and possibly further to \code{\link[prediction]{prediction}} methods. This can be useful, for example, for setting \code{type} (predicted value type), \code{eps} (precision), or \code{category} (category for multi-category outcome models), etc.
#' @details Methods for this generic return a \dQuote{margins} object, which is a data frame consisting of the original data, predicted values and standard errors thereof, estimated marginal effects from the model \code{model}, with attributes describing various features of the marginal effects estimates.
#' 
#' Some modelling functions set \code{model = FALSE} by default. For \code{margins} to work best, this should be set to \code{TRUE}. Otherwise the \code{data} argument to \code{margins} is probably required.
#' 
#' See \code{\link{dydx}} for details on estimation of marginal effects.
#' 
#' Methods are currently implemented for the following object classes:
#' \itemize{
#'   \item \dQuote{betareg}, see \code{\link[betareg]{betareg}}
#'   \item \dQuote{glm}, see \code{\link[stats]{glm}}, \code{\link[MASS]{glm.nb}}
#'   \item \dQuote{ivreg}, see \code{\link[AER]{ivreg}}
#'   \item \dQuote{lm}, see \code{\link[stats]{lm}}
#'   \item \dQuote{loess}, see \code{\link[stats]{loess}}
#'   \item \dQuote{merMod}, see \code{\link[lme4]{lmer}}
#'   \item \dQuote{nnet}, see \code{\link[nnet]{nnet}}
#'   \item \dQuote{polr}, see \code{\link[MASS]{polr}}
#'   \item \dQuote{svyglm}, see \code{\link[survey]{svyglm}}
#' }
#'
#' The \code{margins} method for objects of class \dQuote{lm} or \dQuote{glm} simply constructs a list of data frames (using \code{\link{build_datalist}}), calculates marginal effects for each data frame (via \code{\link{marginal_effects}} and, in turn, \code{\link[prediction]{prediction}}), and row-binds the results together. Alternatively, you can use \code{\link{marginal_effects}} to retrieve a data frame of marginal effects without constructing a \dQuote{margins} object. That can be efficient for plotting, etc., given the time-consuming nature of variance estimation.
#' 
#' The choice of \code{vce} may be important. The default variance-covariance estimation procedure (\code{vce = "delta"}) uses the delta method to estimate marginal effect variances. This is the fastest method. When \code{vce = "simulation"}, coefficient estimates are repeatedly drawn from the asymptotic (multivariate normal) distribution of the model coefficients and each draw is used to estimate marginal effects, with the variance based upon the dispersion of those simulated effects. The number of interations used is given by \code{iterations}. For \code{vce = "bootstrap"}, the bootstrap is used to repeatedly subsample \code{data} and the variance of marginal effects is estimated from the variance of the bootstrap distribution. This method is markedly slower than the other two procedures. Again, \code{iterations} regulates the number of bootstrap subsamples to draw.
#'
#' @return A data frame of class \dQuote{margins} containing the contents of \code{data}, fitted values for \code{model}, the standard errors of the fitted values, and any estimated marginal effects. If \code{at = NULL} (the default), then the data frame will have a number of rows equal to \code{nrow(data)}. Otherwise, the number of rows will be a multiple thereof based upon the intersection of values specified in \code{at}. Columns containing marginal effects are distinguished by their name (prefixed by \code{dydx_}). These columns can be extracted from a \dQuote{margins} object using, for example, \code{marginal_effects(margins(model))}. Columns prefixed by \code{Var_} specify the variances of the \emph{average} marginal effects, whereas (optional) columns prefixed by \code{SE_} contain observation-specific standard errors. A special list column, \code{.at}, will contain information on the combination of values from \code{at} reflected in each row observation. The \code{summary.margins()} method provides for pretty printing of the results. A variance-covariance matrix for the average marginal effects is returned as an attribute (though behavior when \code{at} is non-NULL is unspecified).
#' @author Thomas J. Leeper
#' @references
#' Greene, W.H. 2012. Econometric Analysis, 7th Ed. Boston: Pearson.
#' 
#' Stata manual: \code{margins}. Retrieved 2014-12-15 from \url{http://www.stata.com/manuals13/rmargins.pdf}.
#' @examples
#' # basic example using linear model
#' require("datasets")
#' x <- lm(mpg ~ cyl * hp + wt, data = head(mtcars))
#' margins(x)
#' 
#' # obtain unit-specific standard errors
#' \dontrun{
#'   margins(x, unit_ses = TRUE)
#' }
#'
#' # use of 'variables' argument to estimate only some MEs
#' summary(margins(x, variables = "hp"))
#' 
#' # use of 'at' argument
#' ## modifying original data values
#' margins(x, at = list(hp = 150))
#' ## AMEs at various data values
#' margins(x, at = list(hp = c(95, 150), cyl = c(4,6)))
#' 
#' # use of 'data' argument to obtain AMEs for a subset of data
#' margins(x, data = mtcars[mtcars[["cyl"]] == 4,])
#' margins(x, data = mtcars[mtcars[["cyl"]] == 6,])
#' 
#' # return discrete differences for continuous terms
#' ## passes 'change' through '...' to dydx()
#' margins(x, change = "sd")
#' 
#' # summary() method
#' summary(margins(x, at = list(hp = c(95, 150))))
#' ## control row order of summary() output
#' summary(margins(x, at = list(hp = c(95, 150))), by_factor = FALSE)
#' 
#' # alternative 'vce' estimation
#' \dontrun{
#'   # bootstrap
#'   margins(x, vce = "bootstrap", iterations = 100L)
#'   # simulation (ala Clarify/Zelig)
#'   margins(x, vce = "simulation", iterations = 100L)
#' }
#' 
#' # specifying a custom `vcov` argument
#' if (require("sandwich")) {
#'   x2 <- lm(Sepal.Length ~ Sepal.Width, data = head(iris))
#'   summary(margins(x2))
#'   ## heteroskedasticity-consistent covariance matrix
#'   summary(margins(x2, vcov = vcovHC(x2)))
#' }
#'
#' # generalized linear model
#' x <- glm(am ~ hp, data = head(mtcars), family = binomial)
#' margins(x, type = "response")
#' margins(x, type = "link")
#' 
#' # multi-category outcome
#' if (requireNamespace("nnet")) {
#'   data("iris3", package = "datasets")
#'   ird <- data.frame(rbind(iris3[,,1], iris3[,,2], iris3[,,3]),
#'                     species = factor(c(rep("s",50), rep("c", 50), rep("v", 50))))
#'   m <- nnet::nnet(species ~ ., data = ird, size = 2, rang = 0.1,
#'                   decay = 5e-4, maxit = 200, trace = FALSE)
#'   margins(m) # default
#'   margins(m, category = "v") # explicit category
#' }
#'
#' @seealso \code{\link{marginal_effects}}, \code{\link{dydx}}, \code{\link[prediction]{prediction}}
#' @keywords models package
#' @import stats
#' @importFrom prediction prediction find_data build_datalist
#' @importFrom MASS mvrnorm
#' @export
margins <- 
function(model, ...) {
    UseMethod("margins")
}

#' @export
prediction::prediction

#' @export
prediction::find_data
