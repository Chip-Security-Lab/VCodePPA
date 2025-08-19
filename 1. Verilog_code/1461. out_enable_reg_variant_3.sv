//SystemVerilog
//IEEE 1364-2005 Verilog
module out_enable_reg(
    input clk, rst,
    input [15:0] data_in,
    input load, out_en,
    output [15:0] data_out
);
    // 定义流水线阶段寄存器 - 优化数据路径
    reg [15:0] stage1_data;
    reg [15:0] stage2_data;
    reg stage1_valid;
    reg stage2_valid;
    
    // 阶段1: 输入数据加载 - 优化控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_data <= 16'h0;
            stage1_valid <= 1'b0;
        end
        else begin
            stage1_valid <= load;
            if (load) begin
                stage1_data <= data_in;
            end
        end
    end
    
    // 阶段2: 数据处理和存储 - 优化控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'h0;
            stage2_valid <= 1'b0;
        end
        else if (stage1_valid) begin
            stage2_data <= stage1_data;
            stage2_valid <= 1'b1;
        end
    end
    
    // 输出逻辑 - 优化三态输出控制
    assign data_out = (out_en && stage2_valid) ? stage2_data : 16'hZ;
endmodule