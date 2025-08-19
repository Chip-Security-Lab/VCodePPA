//SystemVerilog
//IEEE 1364-2005 Verilog
// Top level module
module touch_decoder (
    input [11:0] x_raw, y_raw,
    output [10:0] x_pos, y_pos
);
    // Internal connections
    wire [10:0] x_scaled, y_scaled;
    
    // Submodule instantiations - using efficient direct instantiation
    coordinate_scaler x_scaler (
        .raw_data(x_raw),
        .scaled_data(x_scaled)
    );
    
    coordinate_scaler y_scaler (
        .raw_data(y_raw),
        .scaled_data(y_scaled)
    );
    
    // Optimized calibration modules with improved timing
    coordinate_calibration x_calibration (
        .scaled_data(x_scaled),
        .calibrated_data(x_pos),
        .calibration_offset(11'd5),
        .enable_scaling(1'b1)
    );
    
    coordinate_calibration y_calibration (
        .scaled_data(y_scaled),
        .calibrated_data(y_pos),
        .calibration_offset(11'd0),
        .enable_scaling(1'b0)
    );
    
endmodule

// Optimized scaling module with simplified logic
module coordinate_scaler (
    input [11:0] raw_data,
    output [10:0] scaled_data
);
    // Optimized bit selection for improved timing
    assign scaled_data = raw_data[11:1];
    
endmodule

// Optimized calibration module with improved timing and area
module coordinate_calibration (
    input [10:0] scaled_data,
    input [10:0] calibration_offset,
    input enable_scaling,
    output [10:0] calibrated_data
);
    // Optimized implementation using continuous assignment
    // Eliminates always block overhead and potential glitches
    assign calibrated_data = enable_scaling ? 
                            (scaled_data + calibration_offset) : 
                            {1'b0, scaled_data[10:1]};
    
endmodule