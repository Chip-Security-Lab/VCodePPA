//SystemVerilog
module source_id_ismu(
    input wire clk, rst_n,
    input wire [7:0] irq,
    input wire ack,
    output reg [2:0] src_id,
    output reg valid
);
    reg [7:0] pending;
    wire [7:0] next_pending;
    wire [7:0] ack_mask;
    wire has_pending;
    
    // 简化的掩码计算
    assign ack_mask = ack ? (8'h1 << src_id) : 8'h0;
    // 优化的下一个待处理状态计算
    assign next_pending = pending | irq & ~ack_mask;
    // 提前计算是否有待处理中断
    assign has_pending = |next_pending;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pending <= 8'h0;
            valid <= 1'b0;
            src_id <= 3'h0;
        end else begin
            pending <= next_pending;
            valid <= has_pending;
            
            // 使用case语句替代if-else结构，提高综合效率
            if (has_pending) begin
                casez(next_pending)
                    8'b????_???1: src_id <= 3'd0;
                    8'b????_??10: src_id <= 3'd1;
                    8'b????_?100: src_id <= 3'd2;
                    8'b????_1000: src_id <= 3'd3;
                    8'b???1_0000: src_id <= 3'd4;
                    8'b??10_0000: src_id <= 3'd5;
                    8'b?100_0000: src_id <= 3'd6;
                    8'b1000_0000: src_id <= 3'd7;
                    default: src_id <= src_id; // 保持现有值
                endcase
            end
        end
    end
endmodule