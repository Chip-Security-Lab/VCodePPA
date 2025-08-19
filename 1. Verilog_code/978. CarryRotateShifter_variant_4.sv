//SystemVerilog
// Top level module
module CarryRotateShifter #(
    parameter WIDTH = 8
)(
    input  wire            clk,
    input  wire            en,
    input  wire            carry_in,
    output wire            carry_out,
    output wire [WIDTH-1:0] data_out
);
    // Internal signals
    wire shift_carry_out;
    wire [WIDTH-1:0] shift_data_out;
    
    // Control module for enabling shifting
    ShiftController u_shift_controller (
        .clk        (clk),
        .en         (en),
        .carry_in   (carry_in),
        .data_in    (data_out),
        .carry_out  (shift_carry_out),
        .data_out   (shift_data_out)
    );
    
    // Register module for storing shift results
    ShiftRegister #(
        .WIDTH      (WIDTH)
    ) u_shift_register (
        .clk        (clk),
        .en         (en),
        .d_in       (shift_data_out),
        .carry_in   (shift_carry_out),
        .data_out   (data_out),
        .carry_out  (carry_out)
    );
    
endmodule

// Module for calculating the next shift values
module ShiftController (
    input  wire            clk,
    input  wire            en,
    input  wire            carry_in,
    input  wire [WIDTH-1:0] data_in,
    output wire            carry_out,
    output wire [WIDTH-1:0] data_out
);
    parameter WIDTH = 8;
    
    assign carry_out = data_in[WIDTH-1];
    assign data_out = {data_in[WIDTH-2:0], carry_in};
    
endmodule

// Module for registering the shifted results
module ShiftRegister #(
    parameter WIDTH = 8
)(
    input  wire            clk,
    input  wire            en,
    input  wire [WIDTH-1:0] d_in,
    input  wire            carry_in,
    output reg  [WIDTH-1:0] data_out,
    output reg             carry_out
);
    
    // Register the shifted data
    always @(posedge clk) begin
        if (en) begin
            data_out <= d_in;
            carry_out <= carry_in;
        end
    end
    
endmodule