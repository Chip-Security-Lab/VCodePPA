//SystemVerilog
module DynMaskMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] dynamic_mask,
    output match
);
    // 掩码数据
    wire [WIDTH-1:0] masked_data = data & dynamic_mask;
    wire [WIDTH-1:0] masked_pattern = pattern & dynamic_mask;
    
    // 查找表辅助减法
    reg [WIDTH-1:0] lut_subtraction_result;
    reg borrow;
    integer i;
    
    always @(*) begin
        borrow = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            case ({masked_data[i], masked_pattern[i], borrow})
                3'b000: begin lut_subtraction_result[i] = 1'b0; borrow = 1'b0; end
                3'b001: begin lut_subtraction_result[i] = 1'b1; borrow = 1'b1; end
                3'b010: begin lut_subtraction_result[i] = 1'b1; borrow = 1'b1; end
                3'b011: begin lut_subtraction_result[i] = 1'b0; borrow = 1'b1; end
                3'b100: begin lut_subtraction_result[i] = 1'b1; borrow = 1'b0; end
                3'b101: begin lut_subtraction_result[i] = 1'b0; borrow = 1'b0; end
                3'b110: begin lut_subtraction_result[i] = 1'b0; borrow = 1'b0; end
                3'b111: begin lut_subtraction_result[i] = 1'b1; borrow = 1'b1; end
                default: begin lut_subtraction_result[i] = 1'b0; borrow = 1'b0; end
            endcase
        end
    end
    
    // 当所有位都为零时匹配
    assign match = (lut_subtraction_result == 8'b0);
endmodule