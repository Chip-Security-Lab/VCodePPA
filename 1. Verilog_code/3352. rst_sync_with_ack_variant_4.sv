//SystemVerilog
module rst_sync_with_ack (
    input  wire clk,          // 时钟信号
    input  wire async_rst_n,  // 异步复位信号（低有效）
    input  wire ack_reset,    // 复位确认信号
    output reg  sync_rst_n,   // 同步复位信号（低有效）
    output reg  rst_active    // 复位激活指示
);
    // 流水线寄存器定义
    reg meta_stage_pipe1;
    reg meta_stage_pipe2;
    reg sync_rst_n_pipe1;
    reg sync_rst_n_pipe2;
    reg rst_active_pipe1;
    reg rst_active_pipe2;
    
    // 流水线控制信号
    reg valid_pipe1, valid_pipe2, valid_pipe3;
    
    // 第1级流水线：捕获异步复位信号
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage_pipe1 <= 1'b0;
            valid_pipe1 <= 1'b1;
        end else begin
            meta_stage_pipe1 <= 1'b1;
            valid_pipe1 <= 1'b1;
        end
    end
    
    // 第2级流水线：同步复位信号
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage_pipe2 <= 1'b0;
            sync_rst_n_pipe1 <= 1'b0;
            valid_pipe2 <= 1'b1;
        end else begin
            meta_stage_pipe2 <= meta_stage_pipe1;
            sync_rst_n_pipe1 <= meta_stage_pipe2;
            valid_pipe2 <= valid_pipe1;
        end
    end
    
    // 第3级流水线：复位状态处理
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n_pipe2 <= 1'b0;
            rst_active_pipe1 <= 1'b1;
            valid_pipe3 <= 1'b1;
        end else begin
            sync_rst_n_pipe2 <= sync_rst_n_pipe1;
            
            // 复位状态逻辑处理
            if (valid_pipe2) begin
                case ({ack_reset, sync_rst_n_pipe1})
                    2'b10, 2'b11: rst_active_pipe1 <= 1'b0; // 确认复位时清除激活状态
                    2'b00, 2'b01: rst_active_pipe1 <= !sync_rst_n_pipe1; // 根据同步复位状态设置激活标志
                endcase
            end
            
            valid_pipe3 <= valid_pipe2;
        end
    end
    
    // 输出寄存器阶段
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n <= 1'b0;
            rst_active <= 1'b1;
        end else begin
            if (valid_pipe3) begin
                sync_rst_n <= sync_rst_n_pipe2;
                rst_active <= rst_active_pipe1;
            end
        end
    end
    
endmodule