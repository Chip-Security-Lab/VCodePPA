//SystemVerilog
`timescale 1ns / 1ps
//========================================================================
// Pipelined Parallel-to-Serial Converter with Shadow Register
// IEEE 1364-2005 Verilog Standard
//========================================================================
module p2s_shadow_reg #(
    parameter WIDTH = 8
)(
    input  wire                clk,            // System clock
    input  wire                rst_n,          // Active-low reset
    input  wire [WIDTH-1:0]    parallel_in,    // Parallel data input
    input  wire                load_parallel,  // Load control signal
    input  wire                shift_en,       // Shift enable signal
    output wire                serial_out,     // Serial data output
    output wire [WIDTH-1:0]    shadow_data     // Shadow register output
);

    //----------------------------------------------------------------------
    // Internal registers for data pipeline
    //----------------------------------------------------------------------
    reg [WIDTH-1:0]    shift_reg_q;           // Main shift register
    reg [WIDTH-1:0]    shadow_reg_q;          // Shadow data register
    reg                serial_out_q;           // Registered serial output
    
    //----------------------------------------------------------------------
    // Combined data path - All registers updated in single always block
    //----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_q <= {WIDTH{1'b0}};
            shadow_reg_q <= {WIDTH{1'b0}};
            serial_out_q <= 1'b0;
        end else begin
            // Update serial output from current shift register
            serial_out_q <= shift_reg_q[WIDTH-1];
            
            // Update shift register
            if (load_parallel) begin
                shift_reg_q <= parallel_in;
            end else if (shift_en) begin
                shift_reg_q <= {shift_reg_q[WIDTH-2:0], 1'b0};
            end
            
            // Update shadow register
            if (load_parallel) begin
                shadow_reg_q <= parallel_in;
            end
        end
    end
    
    // Connect registers to outputs
    assign serial_out = serial_out_q;
    assign shadow_data = shadow_reg_q;
    
endmodule