//SystemVerilog
module pipe_prefetch_buf #(parameter DW=32) (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    output wire ready_out,
    input  wire [DW-1:0] data_in,
    output wire valid_out,
    input  wire ready_in,
    output wire [DW-1:0] data_out
);
    // 寄存器声明 - 注意stage0已移动到组合逻辑之后
    reg [DW-1:0] stage1_data;
    reg [DW-1:0] stage2_data;
    
    // 有效信号寄存器 - 同样stage0已移动
    reg stage1_valid;
    reg stage2_valid;
    
    // 输入数据寄存器化 - 数据直接流向stage1
    wire [DW-1:0] prefetch_data;
    wire prefetch_valid;
    
    // 流水线阶段准备信号计算（反压控制）
    wire stage1_ready;
    wire stage2_ready;
    
    // 输入预取数据和有效信号（将stage0向前移动）
    assign prefetch_data = data_in;
    assign prefetch_valid = valid_in;
    
    // 基于下游准备状态的反压传播
    assign stage2_ready = ready_in || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign ready_out = stage1_ready; // 反压直接从stage1传回输入
    
    // 输出赋值
    assign data_out = stage2_data;
    assign valid_out = stage2_valid;
    
    // 流水线阶段1 - 现在直接处理输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_data <= {DW{1'b0}};
        end else if (stage1_ready) begin
            stage1_valid <= prefetch_valid;
            if (prefetch_valid) begin
                stage1_data <= prefetch_data;
            end
        end
    end
    
    // 流水线阶段2 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_data <= {DW{1'b0}};
        end else if (stage2_ready) begin
            stage2_valid <= stage1_valid;
            if (stage1_valid) begin
                stage2_data <= stage1_data;
            end
        end
    end
endmodule