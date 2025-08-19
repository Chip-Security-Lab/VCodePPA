//SystemVerilog
module preloadable_counter (
    input wire clk,
    input wire sync_rst,
    input wire load,
    input wire en,
    input wire [5:0] preset_val,
    output reg [5:0] q,
    // 流水线控制信号
    input wire pipeline_valid_in,
    output reg pipeline_valid_out,
    input wire pipeline_ready_in,
    output wire pipeline_ready_out
);

    // 流水线阶段1 - 输入捕获
    reg [5:0] preset_val_stage1;
    reg load_stage1, en_stage1;
    reg valid_stage1;
    
    // 流水线阶段2 - 处理逻辑
    reg [5:0] counter_stage2;
    reg valid_stage2;
    
    // 流水线阶段3 - 输出结果
    reg [5:0] result_stage3;
    reg valid_stage3;
    
    // 流水线就绪信号生成
    assign pipeline_ready_out = !valid_stage1 || pipeline_ready_in;
    
    // 阶段1: 输入捕获的复位逻辑
    always @(posedge clk) begin
        if (sync_rst) begin
            preset_val_stage1 <= 6'b0;
            load_stage1 <= 1'b0;
            en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段1: 输入捕获的正常操作逻辑
    always @(posedge clk) begin
        if (!sync_rst && pipeline_ready_out) begin
            preset_val_stage1 <= preset_val;
            load_stage1 <= load;
            en_stage1 <= en;
            valid_stage1 <= pipeline_valid_in;
        end
    end
    
    // 阶段2: 处理逻辑的复位逻辑
    always @(posedge clk) begin
        if (sync_rst) begin
            counter_stage2 <= 6'b0;
            valid_stage2 <= 1'b0;
        end
    end
    
    // 阶段2: 处理逻辑的有效性控制
    always @(posedge clk) begin
        if (!sync_rst && (pipeline_ready_in || !valid_stage2)) begin
            if (valid_stage1)
                valid_stage2 <= 1'b1;
            else
                valid_stage2 <= 1'b0;
        end
    end
    
    // 阶段2: 计数器值计算逻辑
    always @(posedge clk) begin
        if (!sync_rst && valid_stage1 && (pipeline_ready_in || !valid_stage2)) begin
            if (load_stage1)
                counter_stage2 <= preset_val_stage1;
            else if (en_stage1)
                counter_stage2 <= q + 1'b1;
            else
                counter_stage2 <= q;
        end
    end
    
    // 阶段3: 输出结果的复位逻辑
    always @(posedge clk) begin
        if (sync_rst) begin
            result_stage3 <= 6'b0;
            valid_stage3 <= 1'b0;
        end
    end
    
    // 阶段3: 结果传递逻辑
    always @(posedge clk) begin
        if (!sync_rst && (pipeline_ready_in || !valid_stage3)) begin
            if (valid_stage2) begin
                result_stage3 <= counter_stage2;
                valid_stage3 <= 1'b1;
            end
            else
                valid_stage3 <= 1'b0;
        end
    end
    
    // 输出寄存器复位逻辑
    always @(posedge clk) begin
        if (sync_rst) begin
            q <= 6'b0;
            pipeline_valid_out <= 1'b0;
        end
    end
    
    // 输出寄存器数据更新逻辑
    always @(posedge clk) begin
        if (!sync_rst && valid_stage3) begin
            q <= result_stage3;
            pipeline_valid_out <= 1'b1;
        end
    end
    
    // 输出有效信号清除逻辑
    always @(posedge clk) begin
        if (!sync_rst && !valid_stage3 && pipeline_ready_in) begin
            pipeline_valid_out <= 1'b0;
        end
    end

endmodule