//SystemVerilog
// IEEE 1364-2005 Verilog standard
module VarShiftAmount #(parameter MAX_SHIFT=4, WIDTH=8) (
    input clk,
    input [MAX_SHIFT-1:0] shift_num,
    input dir, // 0-left 1-right
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] shift_result;
    
    always @(*) begin
        if (dir == 1'b0) begin
            shift_result = din << shift_num;
        end
        else if (dir == 1'b1) begin
            shift_result = din >> shift_num;
        end
        else begin
            shift_result = din;
        end
    end
    
    always @(posedge clk) begin
        dout <= shift_result;
    end
    
endmodule