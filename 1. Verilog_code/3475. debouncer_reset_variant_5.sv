//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: debouncer_reset_top.v
// Description: Top level module for button debouncing with reset functionality
// Pipeline-optimized for higher clock frequency
///////////////////////////////////////////////////////////////////////////////

module debouncer_reset_top #(
    parameter DELAY = 16
)(
    input  wire clk,         // System clock
    input  wire rst,         // Reset signal
    input  wire button_in,   // Raw button input
    output wire button_out   // Debounced button output
);

    // Internal signals
    wire [DELAY-1:0] shift_reg_data;
    wire all_ones, all_zeros;
    
    // Pipeline stage signals
    wire all_ones_stage1, all_zeros_stage1;

    // Shift register submodule instance
    shift_register #(
        .WIDTH(DELAY)
    ) shift_reg_inst (
        .clk        (clk),
        .rst        (rst),
        .data_in    (button_in),
        .reg_out    (shift_reg_data)
    );

    // Detector submodule instance - first pipeline stage
    pattern_detector #(
        .WIDTH(DELAY)
    ) detector_inst (
        .clk        (clk),
        .rst        (rst),
        .data_in    (shift_reg_data),
        .all_ones   (all_ones),
        .all_zeros  (all_zeros)
    );
    
    // Output logic submodule instance - second pipeline stage
    output_controller output_ctrl_inst (
        .clk        (clk),
        .rst        (rst),
        .all_ones   (all_ones),
        .all_zeros  (all_zeros),
        .button_out (button_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Shift register module - captures button state history
///////////////////////////////////////////////////////////////////////////////

module shift_register #(
    parameter WIDTH = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output reg [WIDTH-1:0] reg_out
);
    // Split shift register into two pipeline stages for better timing
    reg [WIDTH/2-1:0] shift_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_stage1 <= {(WIDTH/2){1'b0}};
            reg_out <= {WIDTH{1'b0}};
        end else begin
            // First half of shift register
            shift_stage1 <= {shift_stage1[WIDTH/2-2:0], data_in};
            // Second half of shift register with pipelined data
            reg_out <= {reg_out[WIDTH-2:WIDTH/2], shift_stage1, reg_out[WIDTH/2-2:0]};
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Pattern detector module - detects stable button states with pipeline stages
///////////////////////////////////////////////////////////////////////////////

module pattern_detector #(
    parameter WIDTH = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] data_in,
    output reg all_ones,
    output reg all_zeros
);
    // Split detection into multiple pipeline stages
    wire all_ones_stage1_upper, all_ones_stage1_lower;
    wire all_zeros_stage1_upper, all_zeros_stage1_lower;
    reg all_ones_stage2, all_zeros_stage2;
    
    // First pipeline stage - split detection into upper and lower halves
    assign all_ones_stage1_upper = &data_in[WIDTH-1:WIDTH/2];
    assign all_ones_stage1_lower = &data_in[WIDTH/2-1:0];
    assign all_zeros_stage1_upper = ~|data_in[WIDTH-1:WIDTH/2];
    assign all_zeros_stage1_lower = ~|data_in[WIDTH/2-1:0];
    
    // Second pipeline stage - combine results
    always @(posedge clk) begin
        if (rst) begin
            all_ones_stage2 <= 1'b0;
            all_zeros_stage2 <= 1'b0;
        end else begin
            all_ones_stage2 <= all_ones_stage1_upper & all_ones_stage1_lower;
            all_zeros_stage2 <= all_zeros_stage1_upper & all_zeros_stage1_lower;
        end
    end
    
    // Final pipeline stage - register output
    always @(posedge clk) begin
        if (rst) begin
            all_ones <= 1'b0;
            all_zeros <= 1'b0;
        end else begin
            all_ones <= all_ones_stage2;
            all_zeros <= all_zeros_stage2;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Output controller module - manages the debounced output state
///////////////////////////////////////////////////////////////////////////////

module output_controller (
    input  wire clk,
    input  wire rst,
    input  wire all_ones,
    input  wire all_zeros,
    output reg  button_out
);
    // Pipelined signal processing
    reg all_ones_stage1, all_zeros_stage1;
    
    // First pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            all_ones_stage1 <= 1'b0;
            all_zeros_stage1 <= 1'b0;
        end else begin
            all_ones_stage1 <= all_ones;
            all_zeros_stage1 <= all_zeros;
        end
    end

    // Second pipeline stage - final output logic
    always @(posedge clk) begin
        if (rst) begin
            button_out <= 1'b0;
        end else begin
            if (all_ones_stage1)
                button_out <= 1'b1;
            else if (all_zeros_stage1)
                button_out <= 1'b0;
            // Otherwise maintain current state
        end
    end

endmodule