//SystemVerilog
module Shift_AND(
    input [2:0] shift_ctrl,
    input [31:0] vec,
    output reg [31:0] out
);
    // 优化的比较逻辑实现
    always @(*) begin
        case (shift_ctrl)
            3'd0: out = vec;
            3'd1: out = vec & 32'hFFFFFFFE;
            3'd2: out = vec & 32'hFFFFFFFC;
            3'd3: out = vec & 32'hFFFFFFF8;
            3'd4: out = vec & 32'hFFFFFFF0;
            3'd5: out = vec & 32'hFFFFFFE0;
            3'd6: out = vec & 32'hFFFFFFC0;
            3'd7: out = vec & 32'hFFFFFF80;
            default: out = vec;
        endcase
    end
endmodule