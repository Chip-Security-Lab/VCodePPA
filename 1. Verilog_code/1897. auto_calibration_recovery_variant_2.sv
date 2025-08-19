//SystemVerilog
// Top-level module
module auto_calibration_recovery (
    input wire clk,
    input wire init_calib,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output wire [9:0] calibrated_out,
    output wire calib_done
);

    wire [9:0] offset_value;
    wire [3:0] current_state;
    
    // State machine control module
    calibration_fsm u_calibration_fsm (
        .clk(clk),
        .init_calib(init_calib),
        .current_state(current_state)
    );
    
    // Offset calculation module
    offset_calculator u_offset_calculator (
        .clk(clk),
        .current_state(current_state),
        .signal_in(signal_in),
        .ref_level(ref_level),
        .offset_value(offset_value)
    );
    
    // Output generation module
    output_generator u_output_generator (
        .clk(clk),
        .current_state(current_state),
        .signal_in(signal_in),
        .offset_value(offset_value),
        .calibrated_out(calibrated_out),
        .calib_done(calib_done)
    );

endmodule

// State machine control module
module calibration_fsm (
    input wire clk,
    input wire init_calib,
    output reg [3:0] current_state
);
    
    localparam MEASURE_REF  = 4'b0001;
    localparam VALIDATE_CAL = 4'b0010;
    localparam CALIB_DONE   = 4'b0100;
    localparam IDLE         = 4'b1000;
    
    always @(posedge clk) begin
        if (init_calib) begin
            current_state <= IDLE;
        end else begin
            case (current_state)
                IDLE:         current_state <= MEASURE_REF;
                MEASURE_REF:  current_state <= VALIDATE_CAL;
                VALIDATE_CAL: current_state <= CALIB_DONE;
                CALIB_DONE:   current_state <= CALIB_DONE;
                default:      current_state <= IDLE;
            endcase
        end
    end
endmodule

// Offset calculation module
module offset_calculator (
    input wire clk,
    input wire [3:0] current_state,
    input wire [9:0] signal_in,
    input wire [9:0] ref_level,
    output reg [9:0] offset_value
);
    
    localparam IDLE = 4'b1000;
    
    always @(posedge clk) begin
        if (current_state == IDLE) begin
            offset_value <= ref_level - signal_in;
        end
    end
endmodule

// Output generation module
module output_generator (
    input wire clk,
    input wire [3:0] current_state,
    input wire [9:0] signal_in,
    input wire [9:0] offset_value,
    output reg [9:0] calibrated_out,
    output reg calib_done
);
    
    localparam MEASURE_REF  = 4'b0001;
    localparam VALIDATE_CAL = 4'b0010;
    localparam CALIB_DONE   = 4'b0100;
    
    always @(posedge clk) begin
        if (current_state == MEASURE_REF || 
            current_state == VALIDATE_CAL || 
            current_state == CALIB_DONE) begin
            calibrated_out <= signal_in + offset_value;
        end
        
        if (current_state == VALIDATE_CAL || current_state == CALIB_DONE) begin
            calib_done <= 1'b1;
        end else begin
            calib_done <= 1'b0;
        end
    end
endmodule