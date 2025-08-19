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

    reg [WIDTH-1:0] int_in_stage1;
    reg [WIDTH*2-1:0] shift_stage2;
    reg [WIDTH*4-1:0] shift_stage3;
    reg [WIDTH*DEPTH-1:0] shift_stage4;

    always @(posedge clk) begin
        int_in_stage1 <= !rst_n ? 0 : int_in;
        shift_stage2 <= !rst_n ? 0 : {shift_stage2[WIDTH-1:0], int_in_stage1};
        shift_stage3 <= !rst_n ? 0 : {shift_stage3[WIDTH*3-1:0], shift_stage2};
        shift_stage4 <= !rst_n ? 0 : {shift_stage4[WIDTH*(DEPTH-1)-1:0], shift_stage3[WIDTH*2-1:0]};
        history <= !rst_n ? 0 : shift_stage4;
    end

endmodule