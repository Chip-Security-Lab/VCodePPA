//SystemVerilog
//IEEE 1364-2005 Verilog
// Top module
module touch_decoder (
    input [11:0] x_raw, y_raw,
    output [10:0] x_pos, y_pos
);
    // Internal signals
    wire [10:0] x_scaled, y_scaled;
    
    // Instantiate sub-modules
    coordinate_processor processor (
        .x_raw(x_raw),
        .y_raw(y_raw),
        .x_pos(x_pos),
        .y_pos(y_pos)
    );
endmodule

// Main coordinate processing module
module coordinate_processor (
    input [11:0] x_raw, y_raw,
    output [10:0] x_pos, y_pos
);
    // Internal signals for connecting sub-modules
    wire [10:0] x_scaled, y_scaled;
    
    // Scaling sub-module instance
    axis_converter x_converter (
        .raw_value(x_raw),
        .processed_value(x_scaled)
    );
    
    axis_converter y_converter (
        .raw_value(y_raw),
        .processed_value(y_scaled)
    );
    
    // Calibration sub-module instances
    x_calibration x_cal (
        .pre_cal(x_scaled),
        .post_cal(x_pos)
    );
    
    y_calibration y_cal (
        .pre_cal(y_scaled),
        .post_cal(y_pos)
    );
endmodule

// Parametrized axis converter module
module axis_converter (
    input [11:0] raw_value,
    output [10:0] processed_value
);
    // Generic conversion of 12-bit raw values to 11-bit scaled values
    assign processed_value = raw_value[11:1];
endmodule

// X-axis specific calibration module
module x_calibration (
    input [10:0] pre_cal,
    output [10:0] post_cal
);
    // X-axis calibration: add offset
    assign post_cal = pre_cal + 11'd5;
endmodule

// Y-axis specific calibration module
module y_calibration (
    input [10:0] pre_cal,
    output [10:0] post_cal
);
    // Y-axis calibration: scale down
    assign post_cal = pre_cal >> 1;
endmodule