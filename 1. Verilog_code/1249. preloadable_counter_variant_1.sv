//SystemVerilog
module preloadable_counter (
    input wire clk, sync_rst, load, en,
    input wire [5:0] preset_val,
    output reg [5:0] q,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 内部流水线寄存器
    reg [5:0] stage1_data, stage2_data;
    
    // 流水线控制信号
    reg stage1_valid, stage2_valid;
    wire stage1_ready, stage2_ready;
    
    // 控制信号状态寄存器
    reg reset_active_stage1, load_active_stage1, increment_active_stage1;
    reg reset_active_stage2, load_active_stage2, increment_active_stage2;
    
    // 反压控制逻辑
    assign ready_out = !stage1_valid || stage1_ready;
    assign stage1_ready = !stage2_valid || stage2_ready;
    assign stage2_ready = !valid_out || ready_in;
    
    // 第一级流水线 - 有效信号寄存
    always @(posedge clk) begin
        if (sync_rst) begin
            stage1_valid <= 1'b0;
        end else if (ready_out && valid_in) begin
            stage1_valid <= 1'b1;
        end else if (stage1_ready) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 第一级流水线 - 控制信号生成
    always @(posedge clk) begin
        if (sync_rst) begin
            reset_active_stage1 <= 1'b0;
            load_active_stage1 <= 1'b0;
            increment_active_stage1 <= 1'b0;
        end else if (ready_out && valid_in) begin
            reset_active_stage1 <= sync_rst;
            load_active_stage1 <= !sync_rst && load;
            increment_active_stage1 <= !sync_rst && !load && en;
        end
    end
    
    // 第一级流水线 - 数据寄存
    always @(posedge clk) begin
        if (sync_rst) begin
            stage1_data <= 6'b0;
        end else if (ready_out && valid_in) begin
            stage1_data <= preset_val;
        end
    end
    
    // 第二级流水线 - 有效信号寄存
    always @(posedge clk) begin
        if (sync_rst) begin
            stage2_valid <= 1'b0;
        end else if (stage1_ready && stage1_valid) begin
            stage2_valid <= 1'b1;
        end else if (stage2_ready) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 第二级流水线 - 控制信号传递
    always @(posedge clk) begin
        if (sync_rst) begin
            reset_active_stage2 <= 1'b0;
            load_active_stage2 <= 1'b0;
            increment_active_stage2 <= 1'b0;
        end else if (stage1_ready && stage1_valid) begin
            reset_active_stage2 <= reset_active_stage1;
            load_active_stage2 <= load_active_stage1;
            increment_active_stage2 <= increment_active_stage1;
        end
    end
    
    // 第二级流水线 - 计数逻辑计算
    always @(posedge clk) begin
        if (sync_rst) begin
            stage2_data <= 6'b0;
        end else if (stage1_ready && stage1_valid) begin
            if (reset_active_stage1)
                stage2_data <= 6'b000000;
            else if (load_active_stage1)
                stage2_data <= stage1_data;
            else if (increment_active_stage1)
                stage2_data <= q + 1'b1;
            else
                stage2_data <= q;
        end
    end
    
    // 第三级流水线 - 输出数据更新
    always @(posedge clk) begin
        if (sync_rst) begin
            q <= 6'b0;
        end else if (stage2_ready && stage2_valid) begin
            q <= stage2_data;
        end
    end
    
    // 第三级流水线 - 输出有效信号更新
    always @(posedge clk) begin
        if (sync_rst) begin
            valid_out <= 1'b0;
        end else if (stage2_ready && stage2_valid) begin
            valid_out <= 1'b1;
        end else if (ready_in) begin
            valid_out <= 1'b0;
        end
    end
endmodule