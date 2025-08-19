//SystemVerilog
module crc_hybrid #(parameter WIDTH=32)(
    input clk, en,
    input [WIDTH-1:0] data,
    output reg [31:0] crc
);
    // 流水线寄存器定义
    reg stage1_valid;
    reg [31:0] stage1_data;
    reg stage2_valid;
    reg [31:0] stage2_result;
    
    // 组合逻辑 - 第一级流水线
    wire [31:0] data_32 = data[31:0];
    
    // 组合逻辑 - 第二级流水线
    wire [31:0] calc_result = (WIDTH > 32) ? 
                   {stage1_data[30:0], 1'b0} ^ 
                   (stage1_data[31] ? 32'h04C11DB7 : 0) : 
                   stage1_data;
    
    // 流水线第一级 - 数据捕获与预处理
    always @(posedge clk) begin
        if (en) begin
            stage1_data <= data_32;
            stage1_valid <= 1'b1;
        end
        else begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 流水线第二级 - CRC计算
    always @(posedge clk) begin
        if (stage1_valid) begin
            stage2_result <= calc_result;
            stage2_valid <= 1'b1;
        end
        else begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 流水线第三级 - 输出结果
    always @(posedge clk) begin
        if (stage2_valid) begin
            crc <= stage2_result;
        end
    end
endmodule