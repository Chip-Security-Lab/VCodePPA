//SystemVerilog
module SyncRecoveryBasic #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] clean_out
);
    // IEEE 1364-2005 Verilog标准
    
    // 流水线寄存器
    reg [WIDTH-1:0] stage1_data;
    reg stage1_valid;
    reg [WIDTH-1:0] stage2_data;
    reg stage2_valid;
    
    // 第一级流水线 - 输入捕获和控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end else if (en) begin
            stage1_data <= noisy_in;
            stage1_valid <= 1'b1;
        end else begin
            stage1_data <= stage1_data;
            stage1_valid <= 1'b0;
        end
    end
    
    // 第二级流水线 - 数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第三级流水线 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_out <= {WIDTH{1'b0}};
        end else if (stage2_valid) begin
            clean_out <= stage2_data;
        end else begin
            clean_out <= clean_out;
        end
    end
endmodule