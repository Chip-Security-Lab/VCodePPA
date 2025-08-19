//SystemVerilog
module DynamicOR(
    input [2:0] shift,
    input [31:0] vec1, vec2,
    output reg [31:0] res
);
    // 使用always块来实现移位和或操作，通过if-else级联结构实现
    always @(*) begin
        if (shift == 3'd0) begin
            res = vec1 | vec2;
        end else if (shift == 3'd1) begin
            res = {vec1[30:0], 1'b0} | vec2;
        end else if (shift == 3'd2) begin
            res = {vec1[29:0], 2'b0} | vec2;
        end else if (shift == 3'd3) begin
            res = {vec1[28:0], 3'b0} | vec2;
        end else if (shift == 3'd4) begin
            res = {vec1[27:0], 4'b0} | vec2;
        end else if (shift == 3'd5) begin
            res = {vec1[26:0], 5'b0} | vec2;
        end else if (shift == 3'd6) begin
            res = {vec1[25:0], 6'b0} | vec2;
        end else if (shift == 3'd7) begin
            res = {vec1[24:0], 7'b0} | vec2;
        end else begin
            res = vec1 | vec2;
        end
    end
endmodule