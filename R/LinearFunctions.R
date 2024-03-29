#' @title Linear and Log-Linear Demand Calibration and Merger Simulation
#' @name Linear-Functions
#' @aliases linear
#' loglinear
#' @description Calibrates consumer demand using either a
#' linear or log-linear demand system and then simulates
#' the prices effect of a merger between two firms
#' under the assumption that all firms in the market
#' are playing a differentiated products Bertrand game.
#' @description Let k denote the number of products produced by all firms.
#' @param prices A length k vector product prices.
#' @param quantities A length k vector of product quantities.
#' @param margins A length k vector of product margins. All margins must
#' be either be between 0 and 1, or NA.
#' @param diversions A k x k matrix of diversion ratios with diagonal
#' elements equal to -1. Default is missing, in which case diversion
#' according to quantity share is assumed.
#' @param symmetry If TRUE, requires the matrix of demand slope coefficients
#' to be symmetric and homogeneous of degree 0 in prices, both of which
#' suffice to make demand consistent with utility maximization theory.
#' Default is TRUE.
#' @param ownerPre EITHER a vector of length k whose values
#' indicate which firm produced a product pre-merger OR
#' a k x k matrix of pre-merger ownership shares.
#' @param ownerPost EITHER a vector of length k whose values
#' indicate which firm produced a product after the merger OR
#' a k x k matrix of post-merger ownership shares.
#' @param mcDelta A length k vector where each element equals the
#' proportional change in a product's marginal costs due to
#' the merger. Default is 0, which assumes that the merger does not
#' affect any products' marginal cost.
#' @param subset A vector of length k where each element equals TRUE if
#' the product indexed by that element should be included in the
#' post-merger simulation and FALSE if it should be excluded.Default is a
#' length k vector of TRUE.
#' @param priceStart A length k vector of prices used as the initial guess
#' in the nonlinear equation solver. Default is \sQuote{prices}.
#' @param control.slopes A list of  \code{\link{optim}}  control parameters
#' passed to the calibration routine optimizer (typically the \code{calcSlopes} method).
#' @param control.equ A list of  \code{\link[BB]{BBsolve}} control parameters
#' passed to the non-linear equation solver (typically the \code{calcPrices} method).
#' @param labels A k-length vector of labels. Default is "Prod#", where
#' \sQuote{#} is a number between 1 and the length of \sQuote{prices}.
#' @param ... Additional options to feed to the solver. See below.
#'
#' @details Using price, quantity, and diversion information for all products
#' in a market, as well as margin information for (at least) all the
#' products of any firm, \code{linear} is able to
#' recover the slopes and intercepts in a Linear demand
#' system and then uses these demand parameters to simulate the price
#' effects of a merger between
#' two firms under the assumption that the firms are playing a
#' differentiated Bertrand pricing game.
#'
#' \code{loglinear} uses the same information as \code{linear} to uncover the
#' slopes and intercepts in a Log-Linear demand system, and then uses these
#' demand parameters to simulate the price effects of a merger of two firms under the
#' assumption that the firms are playing a
#' differentiated Bertrand pricing game.
#'
#'
#' \sQuote{diversions} must be a square matrix whose off-diagonal elements [i,j] estimate the diversion ratio from product i to product j
#' (i.e. the estimated fraction of i's sales that go to j due to a small
#'   increase in i's price). Off-diagonal elements are restricted to be
#' non-negative (products are assumed to be substitutes), diagonal elements
#' must equal -1, and rows must sum to 0 (negative if you wish to include an outside good) . If \sQuote{diversions} is missing, then diversion according to quantity share is assumed.
#'
#'
#'
#' \sQuote{ownerPre} and \sQuote{ownerPost} values will typically be equal to either 0
#' (element [i,j] is not commonly owned) or 1 (element [i,j] is commonly
#'                                             owned), though these matrices may take on any value between 0 and 1 to
#' account for partial ownership.
#'
#'
#' Under linear demand, an analytic solution to the Bertrand pricing game
#' exists. However, this solution can at times produce negative
#' equilibrium quantities. To accommodate this issue, \code{linear}
#' uses \code{\link{constrOptim}}  to
#' find equilibrium prices with non-negative quantities. \code{...} may
#' be used to change the default options for \link{constrOptim}.
#'
#' \code{loglinear} uses the non-linear equation solver
#' \code{\link[BB]{BBsolve}} to find equilibrium prices.  \code{...} may
#' be used to change the default options for \code{\link[BB]{BBsolve}}.
#'
#' @return \code{linear} returns an instance of class \code{\linkS4class{Linear}}.
#' \code{loglinear} returns an instance of \code{\linkS4class{LogLin}}, a
#' child class of \code{\linkS4class{Linear}}.
#' @seealso \code{\link{aids}} for a demand system based on revenue shares rather than quantities.
#' @author Charles Taragin \email{ctaragin+antitrustr@gmail.com}
#' @references von Haefen, Roger (2002).
#' \dQuote{A Complete Characterization Of The Linear, Log-Linear, And Semi-Log
#' Incomplete Demand System Models.}
#' \emph{Journal of Agricultural and Resource Economics}, \bold{27}(02).
#' \doi{10.22004/ag.econ.31118}.
#'
#' @examples
#' ## Simulate a merger between two single-product firms in a
#' ## three-firm market with linear demand with diversions
#' ## that are proportional to shares.
#' ## This example assumes that the merger is between
#' ## the first two firms
#'
#'
#'
#' n <- 3 #number of firms in market
#' price    <- c(2.9,3.4,2.2)
#' quantity <- c(650,998,1801)
#' margin <- c(.435,.417,.370)
#'
#'
#' #simulate merger between firms 1 and 2
#' owner.pre <- diag(n)
#' owner.post <- owner.pre
#' owner.post[1,2] <- owner.post[2,1] <- 1
#'
#'
#'
#' result.linear <- linear(price,quantity,margin,ownerPre=owner.pre,ownerPost=owner.post)
#'
#' print(result.linear)           # return predicted price change
#' summary(result.linear)         # summarize merger simulation
#'
#' elast(result.linear,TRUE)      # returns premerger elasticities
#' elast(result.linear,FALSE)     # returns postmerger elasticities
#'
#' diversion(result.linear,TRUE)  # returns premerger diversion ratios
#' diversion(result.linear,FALSE) # returns postmeger diversion ratios
#'
#' cmcr(result.linear)            # returns the compensating marginal cost reduction
#'
#' CV(result.linear)              # returns representative agent compensating variation
#'
#'
#' ## Implement the Hypothetical Monopolist Test
#' ## for products 1 and 2 using a 5\% SSNIP
#'
#' #HypoMonTest(result.linear,prodIndex=1:2)
#'
#'
#' ## Get a detailed description of the 'Linear' class slots
#' showClass("Linear")
#'
#' ## Show all methods attached to the 'Linear' Class
#' showMethods(classes="Linear")
#'
#' ## Show which class have their own 'elast' method
#' showMethods("elast")
#'
#' ## Show the method definition for 'elast' and Class 'Linear'
#' getMethod("elast","Linear")
#'
#' @include HHIFunctions.R
NULL

#'@rdname Linear-Functions
#'@export
linear <- function(prices,quantities,margins, diversions, symmetry=TRUE,
                   ownerPre,ownerPost,
                   mcDelta=rep(0,length(prices)),
                   subset=rep(TRUE,length(prices)),
                   priceStart=prices,
                   control.slopes,
                   labels=paste("Prod",1:length(prices),sep=""),
                   ...
){

  shares <- quantities/sum(quantities)

  if(missing(diversions)){
    diversions <- tcrossprod(1/(1-shares),shares)
    diag(diversions) <- -1.000000001 #correct potential floating point issue

  }


  result <- new("Linear",prices=prices, quantities=quantities,margins=margins,
                shares=shares,mcDelta=mcDelta, subset=subset,
                ownerPre=ownerPre,diversion=diversions, symmetry=symmetry,
                ownerPost=ownerPost, priceStart=priceStart,labels=labels)


  if(!missing(control.slopes)){
    result@control.slopes <- control.slopes
  }


  ## Convert ownership vectors to ownership matrices
  result@ownerPre  <- ownerToMatrix(result,TRUE)
  result@ownerPost <- ownerToMatrix(result,FALSE)

  
  ## Calculate Demand Slope Coefficients and Intercepts
  result <- calcSlopes(result)

 

  ## Calculate marginal cost
  result@mcPre <-  calcMC(result,TRUE)
  result@mcPost <- calcMC(result,FALSE)

  result@pricePre  <- calcPrices(result,TRUE,...)
  result@pricePost <- calcPrices(result,FALSE,subset=subset,...)


  return(result)

}


#'@rdname Linear-Functions
#'@export
loglinear <- function(prices,quantities,margins,diversions,
                      ownerPre,ownerPost,
                      mcDelta=rep(0,length(prices)),
                      subset=rep(TRUE,length(prices)),
                      priceStart=prices,
                      control.equ,
                      labels=paste("Prod",1:length(prices),sep=""),...
){




  shares=quantities/sum(quantities)


  if(missing(diversions)){
    diversions <-  tcrossprod(1/(1-shares),shares)
    diag(diversions) <- -1.000000001 #correct potential floating point issue
  }
  
  ##temporary fix for calcSlopes, which hangs when diagonal of diversion matrix
  ## equals -1.
  
  if(isTRUE(all.equal(diag(diversions),rep(-1,length(quantities))))) diag(diversions) <- -1.000000001


  result <- new("LogLin",prices=prices, quantities=quantities,margins=margins,
                shares=shares,mcDelta=mcDelta, subset=subset, priceStart=priceStart,
                ownerPre=ownerPre,diversion=diversions,
                ownerPost=ownerPost, labels=labels)


  if(!missing(control.equ)){
    result@control.equ <- control.equ
  }

  ## Convert ownership vectors to ownership matrices
  result@ownerPre  <- ownerToMatrix(result,TRUE)
  result@ownerPost <- ownerToMatrix(result,FALSE)

  ## Calculate Demand Slope Coefficients
  result <- calcSlopes(result)

  ## Calculate marginal cost
  result@mcPre <-  calcMC(result,TRUE)
  result@mcPost <- calcMC(result,FALSE)


  ## Calculate pre and post merger equilibrium prices
  result@pricePre  <- calcPrices(result,TRUE,...)
  result@pricePost <- calcPrices(result,FALSE,subset=subset,...)


  return(result)

}
