//SystemVerilog
module counter_pause #(parameter WIDTH=4) (
    input wire clk,            // 时钟信号
    input wire rst,            // 复位信号
    input wire pause,          // 暂停计数控制信号
    input wire ready_in,       // 输入就绪信号
    output wire ready_out,     // 输出就绪信号
    output wire valid_out,     // 输出有效信号
    output reg [WIDTH-1:0] cnt // 计数器输出
);
    // 流水线阶段定义
    // Stage 1: 控制逻辑阶段
    // Stage 2: 计算阶段
    // Stage 3: 输出阶段
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    wire count_enable_stage1;
    reg [WIDTH-1:0] cnt_stage1, cnt_stage2;
    reg pause_stage1, pause_stage2;
    
    // 流水线控制逻辑
    assign count_enable_stage1 = !pause && !rst && ready_in;
    assign ready_out = !valid_stage1 || (valid_stage3 && ready_in);
    assign valid_out = valid_stage3;
    
    // 阶段1: 控制逻辑阶段
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            pause_stage1 <= 1'b0;
            cnt_stage1 <= {WIDTH{1'b0}};
        end else if (ready_out) begin
            valid_stage1 <= count_enable_stage1;
            pause_stage1 <= pause;
            cnt_stage1 <= cnt;
        end
    end
    
    // 阶段2: 计算阶段
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            pause_stage2 <= 1'b0;
            cnt_stage2 <= {WIDTH{1'b0}};
        end else begin
            valid_stage2 <= valid_stage1;
            pause_stage2 <= pause_stage1;
            if (valid_stage1 && !pause_stage1) begin
                cnt_stage2 <= cnt_stage1 + 1'b1;
            end else if (valid_stage1) begin
                cnt_stage2 <= cnt_stage1;
            end
        end
    end
    
    // 阶段3: 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
            cnt <= {WIDTH{1'b0}};
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                cnt <= cnt_stage2;
            end
        end
    end

endmodule