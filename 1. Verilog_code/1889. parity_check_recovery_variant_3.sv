//SystemVerilog
module parity_check_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire parity_in,
    output reg [7:0] data_out,
    output reg valid,
    output reg error
);
    // 使用并行寄存器块以提高代码清晰度
    reg [7:0] data_in_reg;
    reg parity_in_reg;
    reg parity_match;
    
    // 优化的奇偶校验计算 - 使用更高效的表达式
    wire calculated_parity;
    assign calculated_parity = ^data_in_reg;
    
    // 单独的输入寄存阶段，减少关键路径
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_reg <= 8'h00;
            parity_in_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            parity_in_reg <= parity_in;
        end
    end
    
    // 优化的比较逻辑 - 使用单独的比较阶段
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            parity_match <= 1'b0;
        end else begin
            parity_match <= ~(parity_in_reg ^ calculated_parity);
        end
    end
    
    // 输出逻辑 - 分离处理以简化关键路径
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'h00;
            valid <= 1'b0;
            error <= 1'b0;
        end else begin
            valid <= 1'b1;  // 在处理后总是有效
            error <= ~parity_match;
            
            if (parity_match) begin
                data_out <= data_in_reg;
            end
            // 在错误情况下保持上一个有效数据
        end
    end
endmodule