//SystemVerilog
module pipeline_buffer (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire valid_in,
    input wire ready_in,
    output reg [15:0] data_out,
    output reg valid_out,
    input wire ready_out
);
    // 增加流水线级数以提高吞吐量
    reg [15:0] stage1_data, stage2_data, stage3_data;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 每级流水线的准备信号
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // 反向传播准备信号，优化逻辑
    assign ready_stage3 = ready_out || !valid_out;
    assign ready_stage2 = ready_stage3 || !valid_stage3;
    assign ready_stage1 = ready_stage2 || !valid_stage2;
    
    // 增加数据处理逻辑 - 简单加工处理以体现流水线效果
    wire [15:0] processed_stage1 = data_in + 16'h1;
    wire [15:0] processed_stage2 = stage1_data + 16'h2;
    wire [15:0] processed_stage3 = stage2_data + 16'h3;
    
    // 流水线控制逻辑 - 分离各级流水线的时序逻辑以减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 16'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            stage1_data <= processed_stage1;
            valid_stage1 <= valid_in && ready_in;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 16'b0;
            valid_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            stage2_data <= processed_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= 16'b0;
            valid_stage3 <= 1'b0;
        end else if (ready_stage3) begin
            stage3_data <= processed_stage3;
            valid_stage3 <= valid_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
            valid_out <= 1'b0;
        end else if (ready_out) begin
            data_out <= stage3_data;
            valid_out <= valid_stage3;
        end
    end
    
    // 流水线状态监测输出 (仅用于调试，合成时可移除)
    /*
    wire [3:0] pipeline_status = {valid_in, valid_stage1, valid_stage2, valid_stage3};
    wire [3:0] pipeline_ready = {ready_in, ready_stage1, ready_stage2, ready_stage3};
    */
endmodule