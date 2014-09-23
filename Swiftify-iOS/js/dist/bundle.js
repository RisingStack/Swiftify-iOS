(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (global){
var liquidPID = require('liquid-pid');
var actualP = 0;
var pidController;

pidController = new liquidPID({
  temp: {
    ref: 67         // Point temperature                                       
  },
  Pmax: 1000,       // Max power (output),

  // Tune the PID Controller
  Kp: 25,           // PID: Kp
  Ki: 1000,         // PID: Ki
  Kd: 9             // PID: Kd
});


global.calculate = function(temp) {
	return pidController.calculate(temp);
}
}).call(this,typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"liquid-pid":2}],2:[function(require,module,exports){
/**
 * Control the PWM relays from the temperature
 *
 * I'm a NodeJS guy not a scientist, so please be a careful!!!
 * FYI: http://en.wikipedia.org/wiki/PID_controller
 *
 * @module controller
 *
 * @author https://github.com/hekike/liquid-pid
 * @licence MIT
 **/

'use strict';


/**
 * This is the description for PIDController.
 *
 * @class PIDController
 * @param {Object} options Initial config
 * @constructor
 */
var PIDController = function (options) {

  options = options || {};
  options.temp = options.temp || {};


// Params of the system
  this._Tref = options.temp.ref || 0;           // Point temperature (This is the temp what you want to reach and hold) (°C)
  this._Pmax = options.Pmax || 4000;            // Max Power, this is the maximum output of your heater (W)  (Yep, this is the output what you want)

//  Params of the PID controller
  this._Kp = options.Kp || 25;                  // Proportional gain, a tuning parameter
  this._Ki = options.Ki || 1000;                // Integral gain, a tuning parameter
  this._Kd = options.Kd || 9;                   // Derivative gain, a tuning parameter

  this._P = 0;                                  // Proportional value ("reduces a large part of the overall error")
  this._I = 0;                                  // Integral value ("reduces the final error in a system")
  this._D = 0;                                  // Derivative value ("helps reduce overshoot and ringing", "~speed")

  this._MaxP = 1000;                            // Limit the maximum value of the abs Proportional (because micro controller registers)
  this._MaxI = 1000;                            // Limit the maximum value of the abs Integral (because micro controller registers)
  this._MaxD = 1000;                            // Limit the maximum value of the abs Derivative (because micro controller registers)
  this._MaxU = 1000;                            // Limit the maximum value of the controller output (it's not equal with our P "output")

// Other variables
  this._e = 0;                                  // Actual error
  this._U = null;                               // Controller output (it's not equal with our P "output")

};


/**
 * Tune the controller
 * you can do this also when you create new controller
 *
 * @method tune
 * @param {Number} Kp
 * @param {Number} Ki
 * @param {Number} Kd
 */
PIDController.prototype.tune = function (Kp, Ki, Kd) {

  if(!isNaN(Kp) || !isNaN(Ki) || !isNaN(Kd)) {
    return;
  }

  this._Kp = Kp;
  this._Ki = Ki;
  this._Kd = Kd;
};


/**
 * Get ref/point temperature
 *
 * @method getRefTemperature
 * @return {Number} temperature
 */
PIDController.prototype.getRefTemperature = function () {
  return this._Tref;
};


/**
 * Set point temperature
 *
 * @method setPoint
 * @param {Number} temp
 * @return {Number} temp
 */
PIDController.prototype.setPoint = function (temp) {

  if(isNaN(temp)) {
    return;
  }

  this._Tref = temp;
  return this._Tref;
};


/**
 * Calculate output
 * do the math magic
 *
 * @method calculate
 * @param {Number} actualTemperature Measured temperature of the water (°C)
 * @return {Number} calculated output (Watt, %, etc.)
 */
PIDController.prototype.calculate = function (actualTemperature) {
  var
    ePrev = 0;                                                // Value of the previous Error

  ePrev = this._e;                                            // Save the error for the next loop
  this._e = this._Tref - actualTemperature;                   // Calculate the actual error

  // Calculate the P
  this._P = this._Kp * this._e;

  if (this._P) {
    this._P = this._MaxP;
  }
  else if (this._P < (-1 * this._MaxP)) {
    this._P = -1 * this._MaxP;
  }

  // Calculate the D
  this._D = this._Kd * (this._e - ePrev);

  if (this._D > this._MaxD) {
    this._D = this._MaxD;
  }
  else if (this._D < (-1 * this._MaxD)) {
    this._D = -1 * this._MaxD;
  }

  // Calculate the I
  this._I += (this._Ki * this._e);

  if (this._I > this._MaxI) {
    this._I = this._MaxI;
  } else if (this._I < (-1 * this._MaxI)) {
    this._I = -1 * this._MaxI;
  }

  // PID algorithm
  this._U = this._P + this._I + this._D;

  // Some value limitation
  if (this._U > this._MaxU) {
    this._U = this._MaxU;
  }
  else if (this._U < 0) {                                    // Power cannot be a negative number
    this._U = 0;                                             // this means that the system can only heating
  }

  // Calculate the output
  // and transform U to the [0..1] interval
  return (this._U / 1000) * this._Pmax;
};


module.exports = PIDController;
},{}]},{},[1])