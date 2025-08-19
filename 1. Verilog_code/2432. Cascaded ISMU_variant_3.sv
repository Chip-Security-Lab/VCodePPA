//SystemVerilog
//IEEE 1364-2005 Verilog
module cascaded_ismu(
    input clk, reset,
    input [1:0] cascade_in,
    input [7:0] local_int,
    input [7:0] local_mask,
    output reg cascade_out,
    output reg [3:0] int_id
);
    reg [7:0] masked_int;
    reg [3:0] local_id;
    reg local_valid;
    
    // 使用优化的优先编码器实现
    always @(*) begin
        masked_int = local_int & ~local_mask;
        local_valid = |masked_int;
        
        // 优先编码器实现 - 使用casez实现更高效的优先级编码
        casez (masked_int)
            8'b????_???1: local_id = 4'd0;
            8'b????_??10: local_id = 4'd1;
            8'b????_?100: local_id = 4'd2;
            8'b????_1000: local_id = 4'd3;
            8'b???1_0000: local_id = 4'd4;
            8'b??10_0000: local_id = 4'd5;
            8'b?100_0000: local_id = 4'd6;
            8'b1000_0000: local_id = 4'd7;
            default:      local_id = 4'd0;
        endcase
    end
    
    // 简化级联逻辑，减少逻辑层级
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_id <= 4'd0;
            cascade_out <= 1'b0;
        end else begin
            // 合并条件以减少选择逻辑
            cascade_out <= local_valid | (|cascade_in);
            
            // 使用优先选择逻辑
            if (local_valid) begin
                int_id <= local_id;
            end else begin
                // 优化级联输入处理
                casez (cascade_in)
                    2'b?1: int_id <= 4'd8;
                    2'b10: int_id <= 4'd9;
                    default: int_id <= int_id; // 保持当前值
                endcase
            end
        end
    end
endmodule