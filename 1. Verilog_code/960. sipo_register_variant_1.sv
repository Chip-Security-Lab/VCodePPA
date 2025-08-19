//SystemVerilog
//===========================================================================
// Filename: sipo_register_top.v
// 
// Description: Serial-in Parallel-out shift register top level module
// with improved architecture for better PPA metrics
//
//===========================================================================

`timescale 1ns / 1ps

module sipo_register_top #(
    parameter N = 8
) (
    input  wire        clk,    // Clock input
    input  wire        rst,    // Reset signal
    input  wire        en,     // Enable signal
    input  wire        s_in,   // Serial input
    output wire [N-1:0] p_out  // Parallel output
);

    // Control signals
    wire shift_enable;
    
    // Instantiate control unit
    sipo_control_unit control_inst (
        .clk          (clk),
        .rst          (rst),
        .en           (en),
        .shift_enable (shift_enable)
    );
    
    // Instantiate shift register data path
    sipo_datapath #(
        .WIDTH        (N)
    ) datapath_inst (
        .clk          (clk),
        .shift_enable (shift_enable),
        .s_in         (s_in),
        .p_out        (p_out)
    );

endmodule

//===========================================================================
// Control unit to handle reset and enable logic
//===========================================================================
module sipo_control_unit (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output wire shift_enable
);

    // Generate shift enable signal based on reset and enable conditions
    assign shift_enable = en && !rst;

endmodule

//===========================================================================
// Datapath module containing the actual shift register functionality
//===========================================================================
module sipo_datapath #(
    parameter WIDTH = 8
) (
    input  wire               clk,
    input  wire               shift_enable,
    input  wire               s_in,
    output wire [WIDTH-1:0]   p_out
);

    // Shift register
    reg [WIDTH-1:0] shift_reg;
    
    // Negative edge triggered shift operation using case structure
    always @(negedge clk) begin
        case(shift_enable)
            1'b1:    shift_reg <= {shift_reg[WIDTH-2:0], s_in};
            1'b0:    shift_reg <= shift_reg;
            default: shift_reg <= shift_reg; // Handle X/Z cases
        endcase
    end
    
    // Output assignment
    assign p_out = shift_reg;

endmodule