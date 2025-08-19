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
    // 可配置数字滤波
    reg [FILTER_DEPTH-1:0] sda_history;
    reg [FILTER_DEPTH-1:0] scl_history;
    
    reg [2:0] sda_sum; // 用于计数1的数量
    reg [2:0] scl_sum; // 用于计数1的数量

    // 滤波算法实现
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
            sda_sum <= sda_sum - sda_history[FILTER_DEPTH-1] + sda_raw;
            scl_sum <= scl_sum - scl_history[FILTER_DEPTH-1] + scl_raw;
            
            // 应用阈值过滤
            sda_filt <= (sda_sum >= THRESHOLD) ? 1'b1 : 1'b0;
            scl_filt <= (scl_sum >= THRESHOLD) ? 1'b1 : 1'b0;
        end
    end

    // 滤波后总线驱动
    assign sda = (sda_oen) ? 1'bz : sda_filt;
    assign scl = (scl_oen) ? 1'bz : scl_filt;
endmodule