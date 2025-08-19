//SystemVerilog
module rst_sync_with_ack (
    input  wire clk,
    input  wire async_rst_n,
    input  wire ack_reset,
    output reg  sync_rst_n,
    output reg  rst_active
);
    // 流水线寄存器
    reg meta_stage1;
    reg meta_stage2;
    reg meta_stage3;
    
    // 流水线控制信号
    reg reset_detected_stage1;
    reg reset_detected_stage2;
    reg reset_detected_stage3;
    
    // 第一级流水线-捕获异步复位：meta_stage1
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage1 <= 1'b0;
        end else begin
            meta_stage1 <= 1'b1;
        end
    end
    
    // 第一级流水线-重置检测逻辑
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            reset_detected_stage1 <= 1'b1;
        end else begin
            reset_detected_stage1 <= (meta_stage1 == 1'b0);
        end
    end
    
    // 第二级流水线-meta信号传递
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage2 <= 1'b0;
        end else begin
            meta_stage2 <= meta_stage1;
        end
    end
    
    // 第二级流水线-重置检测信号传递
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            reset_detected_stage2 <= 1'b1;
        end else begin
            reset_detected_stage2 <= reset_detected_stage1;
        end
    end
    
    // 第三级流水线-meta信号传递
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage3 <= 1'b0;
        end else begin
            meta_stage3 <= meta_stage2;
        end
    end
    
    // 第三级流水线-重置检测信号传递
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            reset_detected_stage3 <= 1'b1;
        end else begin
            reset_detected_stage3 <= reset_detected_stage2;
        end
    end
    
    // 同步复位信号生成
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n <= 1'b0;
        end else begin
            sync_rst_n <= meta_stage3;
        end
    end
    
    // 复位活动状态控制逻辑
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_active <= 1'b1;
        end else begin
            if (ack_reset) begin
                rst_active <= 1'b0;
            end else if (reset_detected_stage3 || !sync_rst_n) begin
                rst_active <= 1'b1;
            end
        end
    end
endmodule