//SystemVerilog
module ITRC_ShiftTracker #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg [WIDTH*DEPTH-1:0] history
);

    reg [WIDTH-1:0] shift_reg [0:DEPTH-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                shift_reg[i] <= {WIDTH{1'b0}};
        end else begin
            shift_reg[0] <= int_in;
            for (i = 1; i < DEPTH; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    always @(*) begin
        for (i = 0; i < DEPTH; i = i + 1)
            history[WIDTH*i +: WIDTH] = shift_reg[i];
    end

endmodule