//SystemVerilog
// IEEE 1364-2005
// Top level module that integrates the control and shift register components
module BiDirShift #(parameter BITS=8) (
    input clk, rst, dir, s_in,
    output [BITS-1:0] q
);
    // Internal signals
    wire [BITS-1:0] shift_data;
    wire reset_signal;
    
    // Instantiate control module
    ShiftControl u_control (
        .clk(clk),
        .rst(rst),
        .reset_signal(reset_signal)
    );
    
    // Instantiate shift register module
    ShiftRegister #(
        .BITS(BITS)
    ) u_shift_reg (
        .clk(clk),
        .reset_signal(reset_signal),
        .dir(dir),
        .s_in(s_in),
        .q(q),
        .shift_data(shift_data)
    );
    
    // Instantiate direction logic module
    DirectionLogic #(
        .BITS(BITS)
    ) u_dir_logic (
        .dir(dir),
        .s_in(s_in),
        .q(q),
        .shift_data(shift_data)
    );
    
endmodule

// Combined control and shift register module with shared clock domain
module ShiftControl (
    input clk, rst,
    output reg reset_signal
);
    always @(posedge clk) begin
        reset_signal <= rst;
    end
endmodule

// Module for the shift register core functionality
module ShiftRegister #(parameter BITS=8) (
    input clk, reset_signal, dir, s_in,
    input [BITS-1:0] shift_data,
    output reg [BITS-1:0] q
);
    always @(posedge clk) begin
        if (reset_signal) begin
            q <= {BITS{1'b0}};
        end else begin
            q <= shift_data;
        end
    end
endmodule

// Module for direction-based data manipulation
module DirectionLogic #(parameter BITS=8) (
    input dir, s_in,
    input [BITS-1:0] q,
    output [BITS-1:0] shift_data
);
    assign shift_data = dir ? {q[BITS-2:0], s_in} : {s_in, q[BITS-1:1]};
endmodule