//SystemVerilog
module ParamOR #(
    parameter WIDTH = 8,
    parameter PIPELINE_STAGES = 2,  // 可配置流水线级数
    parameter FANOUT_STAGES = 2     // 扇出缓冲级数
) (
    input wire clk,                 // 时钟信号
    input wire rst_n,               // 复位信号
    input wire [WIDTH-1:0] in1, in2,
    input wire valid_in,            // 输入有效信号
    output reg [WIDTH-1:0] result,
    output reg valid_out            // 输出有效信号
);
    // 内部流水线寄存器和有效信号
    reg [WIDTH-1:0] stage1_in1, stage1_in2;
    reg [WIDTH-1:0] pipeline_result;
    reg stage1_valid;
    
    // 有效信号扇出缓冲
    reg [FANOUT_STAGES-1:0] valid_in_buf;
    reg [FANOUT_STAGES-1:0] stage1_valid_buf;
    
    // 输入数据扇出缓冲 - 将大宽度总线分片来降低每个缓冲器的负载
    reg [WIDTH/2-1:0] in1_buf_low, in1_buf_high;
    reg [WIDTH/2-1:0] in2_buf_low, in2_buf_high;
    reg [WIDTH/2-1:0] stage1_in1_buf_low, stage1_in1_buf_high;
    reg [WIDTH/2-1:0] stage1_in2_buf_low, stage1_in2_buf_high;
    
    // 有效信号扇出缓冲更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_buf <= {FANOUT_STAGES{1'b0}};
            stage1_valid_buf <= {FANOUT_STAGES{1'b0}};
        end else begin
            valid_in_buf <= {valid_in_buf[FANOUT_STAGES-2:0], valid_in};
            stage1_valid_buf <= {stage1_valid_buf[FANOUT_STAGES-2:0], stage1_valid};
        end
    end
    
    // 输入数据缓冲 - 分段缓存以减少扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_buf_low <= {(WIDTH/2){1'b0}};
            in1_buf_high <= {(WIDTH/2){1'b0}};
            in2_buf_low <= {(WIDTH/2){1'b0}};
            in2_buf_high <= {(WIDTH/2){1'b0}};
        end else begin
            in1_buf_low <= in1[WIDTH/2-1:0];
            in1_buf_high <= in1[WIDTH-1:WIDTH/2];
            in2_buf_low <= in2[WIDTH/2-1:0];
            in2_buf_high <= in2[WIDTH-1:WIDTH/2];
        end
    end
    
    // 流水线第一级 - 使用缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in1 <= {WIDTH{1'b0}};
            stage1_in2 <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            
            stage1_in1_buf_low <= {(WIDTH/2){1'b0}};
            stage1_in1_buf_high <= {(WIDTH/2){1'b0}};
            stage1_in2_buf_low <= {(WIDTH/2){1'b0}};
            stage1_in2_buf_high <= {(WIDTH/2){1'b0}};
        end else begin
            stage1_in1[WIDTH/2-1:0] <= in1_buf_low;
            stage1_in1[WIDTH-1:WIDTH/2] <= in1_buf_high;
            stage1_in2[WIDTH/2-1:0] <= in2_buf_low;
            stage1_in2[WIDTH-1:WIDTH/2] <= in2_buf_high;
            stage1_valid <= valid_in_buf[0];
            
            // 额外的缓冲寄存器用于下一级
            stage1_in1_buf_low <= stage1_in1[WIDTH/2-1:0];
            stage1_in1_buf_high <= stage1_in1[WIDTH-1:WIDTH/2];
            stage1_in2_buf_low <= stage1_in2[WIDTH/2-1:0];
            stage1_in2_buf_high <= stage1_in2[WIDTH-1:WIDTH/2];
        end
    end
    
    // 流水线第二级 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_result <= {WIDTH{1'b0}};
            result <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (PIPELINE_STAGES == 1) begin
            // 单级流水线 - 直接使用缓冲后的输入信号
            result[WIDTH/2-1:0] <= in1_buf_low | in2_buf_low;
            result[WIDTH-1:WIDTH/2] <= in1_buf_high | in2_buf_high;
            valid_out <= valid_in_buf[FANOUT_STAGES-1];
        end else if (PIPELINE_STAGES >= 2) begin
            // 双级或多级流水线 - 使用缓冲后的中间结果
            pipeline_result[WIDTH/2-1:0] <= stage1_in1_buf_low | stage1_in2_buf_low;
            pipeline_result[WIDTH-1:WIDTH/2] <= stage1_in1_buf_high | stage1_in2_buf_high;
            result <= pipeline_result;
            valid_out <= stage1_valid_buf[FANOUT_STAGES-1];
        end
    end
    
endmodule