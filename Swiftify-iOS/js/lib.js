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