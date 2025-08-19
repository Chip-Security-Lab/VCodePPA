//SystemVerilog
//IEEE 1364-2005 Verilog
//Top-level module
module frac_div #(parameter M=3, N=7) (
    input  wire clk, 
    input  wire rst,
    output wire out
);
    // Internal signals for connecting sub-modules
    wire [7:0] acc_value;
    wire       update_acc;
    wire [7:0] next_acc;
    wire       next_out;

    // Accumulator module instance
    accumulator u_accumulator (
        .clk        (clk),
        .rst        (rst),
        .next_acc   (next_acc),
        .acc_value  (acc_value),
        .out        (out)
    );

    // Accumulator update logic module instance
    acc_update_logic #(
        .M          (M),
        .N          (N)
    ) u_acc_update_logic (
        .acc_value  (acc_value),
        .next_acc   (next_acc),
        .next_out   (next_out)
    );

endmodule

//Accumulator register module
module accumulator (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] next_acc,
    output reg  [7:0] acc_value,
    output reg        out
);
    always @(posedge clk) begin
        if (rst) begin
            acc_value <= 8'd0;
            out <= 1'b0;
        end
        else begin
            acc_value <= next_acc;
            out <= (next_acc >= 8'd7) ? 1'b1 : 1'b0;
        end
    end
endmodule

//Accumulator update logic module
module acc_update_logic #(
    parameter M = 3,
    parameter N = 7
) (
    input  wire [7:0] acc_value,
    output wire [7:0] next_acc,
    output wire       next_out
);
    // Determine the next accumulator value
    assign next_acc = (acc_value >= N) ? (acc_value + M - N) : (acc_value + M);
    
    // Determine the next output value
    assign next_out = (next_acc >= N) ? 1'b1 : 1'b0;
endmodule