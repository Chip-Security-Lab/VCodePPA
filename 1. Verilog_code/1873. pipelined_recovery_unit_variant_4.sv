//SystemVerilog
module pipelined_recovery_unit #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire in_valid,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg out_valid,
    // 添加流水线控制信号
    input wire ready_in,
    output wire ready_out
);
    // 流水线寄存器和控制信号
    reg [DATA_WIDTH-1:0] stage1_data, stage2_data, stage3_data;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 流水线状态控制
    reg pipeline_stall;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // 反向压力控制
    assign ready_out = ~pipeline_stall;
    assign stage3_ready = 1'b1; // 最后阶段永远准备好接收数据
    assign stage2_ready = ~stage3_valid | stage3_ready;
    assign stage1_ready = ~stage2_valid | stage2_ready;
    
    // 流水线处理逻辑
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // 流水线寄存器复位
            stage1_data <= {DATA_WIDTH{1'b0}};
            stage2_data <= {DATA_WIDTH{1'b0}};
            stage3_data <= {DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            stage3_valid <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
            pipeline_stall <= 1'b0;
        end else begin
            // 第三阶段 - 输出
            if (stage3_ready) begin
                data_out <= stage3_valid ? stage3_data : data_out;
                out_valid <= stage3_valid;
                
                if (stage2_valid && stage2_ready) begin
                    stage3_data <= stage2_data;
                    stage3_valid <= stage2_valid;
                end else if (~stage2_valid) begin
                    stage3_valid <= 1'b0;
                end
            end
            
            // 第二阶段 - 中间处理
            if (stage2_ready) begin
                if (stage1_valid && stage1_ready) begin
                    stage2_data <= stage1_data;
                    stage2_valid <= stage1_valid;
                end else if (~stage1_valid) begin
                    stage2_valid <= 1'b0;
                end
            end
            
            // 第一阶段 - 输入
            if (stage1_ready) begin
                if (in_valid && ready_in) begin
                    stage1_data <= data_in;
                    stage1_valid <= 1'b1;
                end else begin
                    stage1_valid <= 1'b0;
                end
            end
            
            // 流水线阻塞检测
            pipeline_stall <= (stage1_valid && ~stage1_ready) || 
                              (stage2_valid && ~stage2_ready) ||
                              (stage3_valid && ~stage3_ready);
        end
    end
endmodule