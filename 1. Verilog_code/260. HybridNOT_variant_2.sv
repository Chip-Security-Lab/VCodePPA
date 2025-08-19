//SystemVerilog
module HybridNOT(
    input wire clk,
    input wire rst_n,
    input wire [7:0] byte_in,
    input wire valid_in,
    output reg [7:0] byte_out,
    output reg valid_out
);
    // 将操作分为4个流水线阶段以提高频率
    // 第1阶段 - 接收输入
    reg [7:0] stage1_data;
    reg stage1_valid;
    
    // 第2阶段 - 处理低4位
    reg [3:0] stage2_lower_bits;
    reg [3:0] stage2_upper_bits;
    reg stage2_valid;
    
    // 第3阶段 - 处理高4位
    reg [3:0] stage3_lower_bits_not;
    reg [3:0] stage3_upper_bits;
    reg stage3_valid;
    
    // 第1阶段 - 数据接收
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'h00;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data <= byte_in;
            stage1_valid <= valid_in;
        end
    end
    
    // 第2阶段 - 拆分数据位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_lower_bits <= 4'h0;
            stage2_upper_bits <= 4'h0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_lower_bits <= stage1_data[3:0];
            stage2_upper_bits <= stage1_data[7:4];
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第3阶段 - 处理低4位取反
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_lower_bits_not <= 4'h0;
            stage3_upper_bits <= 4'h0;
            stage3_valid <= 1'b0;
        end else begin
            stage3_lower_bits_not <= ~stage2_lower_bits; // 低4位取反
            stage3_upper_bits <= stage2_upper_bits;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 第4阶段 - 处理高4位取反并组合输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_out <= 8'h00;
            valid_out <= 1'b0;
        end else begin
            byte_out <= {~stage3_upper_bits, stage3_lower_bits_not}; // 高4位取反并与已取反的低4位组合
            valid_out <= stage3_valid;
        end
    end
    
endmodule