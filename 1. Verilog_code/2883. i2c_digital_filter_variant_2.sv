//SystemVerilog
module i2c_digital_filter #(
    parameter FILTER_DEPTH = 4,
    parameter THRESHOLD = 3
)(
    input clk,
    input rst_n,
    input sda_raw,
    input scl_raw,
    output reg sda_filt,
    output reg scl_filt,
    output sda,
    output scl,
    input sda_oen,
    input scl_oen
);
    // 内部信号定义
    reg [FILTER_DEPTH-1:0] sda_history;
    reg [FILTER_DEPTH-1:0] scl_history;
    reg [2:0] sda_sum;
    reg [2:0] scl_sum;
    
    wire [2:0] sda_sum_next;
    wire [2:0] scl_sum_next;
    wire sda_filt_next;
    wire scl_filt_next;
    
    // ===== 组合逻辑部分 =====
    
    // 计算下一个周期的累加和
    assign sda_sum_next = sda_sum - sda_history[FILTER_DEPTH-1] + sda_raw;
    assign scl_sum_next = scl_sum - scl_history[FILTER_DEPTH-1] + scl_raw;
    
    // 阈值判断逻辑
    assign sda_filt_next = (sda_sum_next >= THRESHOLD) ? 1'b1 : 1'b0;
    assign scl_filt_next = (scl_sum_next >= THRESHOLD) ? 1'b1 : 1'b0;
    
    // 滤波后总线驱动逻辑
    assign sda = sda_oen ? 1'bz : sda_filt;
    assign scl = scl_oen ? 1'bz : scl_filt;
    
    // ===== 时序逻辑部分 =====
    
    // 更新历史和总和寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_history <= {FILTER_DEPTH{1'b1}};
            scl_history <= {FILTER_DEPTH{1'b1}};
            sda_sum <= FILTER_DEPTH;
            scl_sum <= FILTER_DEPTH;
            sda_filt <= 1'b1;
            scl_filt <= 1'b1;
        end else begin
            // 更新历史寄存器
            sda_history <= {sda_history[FILTER_DEPTH-2:0], sda_raw};
            scl_history <= {scl_history[FILTER_DEPTH-2:0], scl_raw};
            
            // 更新求和寄存器
            sda_sum <= sda_sum_next;
            scl_sum <= scl_sum_next;
            
            // 更新滤波输出
            sda_filt <= sda_filt_next;
            scl_filt <= scl_filt_next;
        end
    end
    
endmodule