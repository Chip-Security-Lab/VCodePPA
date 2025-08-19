//SystemVerilog
//IEEE 1364-2005
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
    
    // 使用$unsigned避免符号扩展问题
    reg [$clog2(FILTER_DEPTH+1)-1:0] sda_sum; // 用于计数1的数量
    reg [$clog2(FILTER_DEPTH+1)-1:0] scl_sum; // 用于计数1的数量

    // 更新SDA和SCL历史寄存器 - 合并相似逻辑减少代码重复
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_history <= {FILTER_DEPTH{1'b1}};
            scl_history <= {FILTER_DEPTH{1'b1}};
        end else begin
            sda_history <= {sda_history[FILTER_DEPTH-2:0], sda_raw};
            scl_history <= {scl_history[FILTER_DEPTH-2:0], scl_raw};
        end
    end

    // 优化的SDA和SCL求和逻辑 - 使用单一过程块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sum <= FILTER_DEPTH;
            scl_sum <= FILTER_DEPTH;
        end else begin
            // 优化比较链，使用单操作进行计算
            sda_sum <= sda_sum + sda_raw - sda_history[FILTER_DEPTH-1];
            scl_sum <= scl_sum + scl_raw - scl_history[FILTER_DEPTH-1];
        end
    end

    // 优化的过滤阈值检查 - 合并两个过程块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_filt <= 1'b1;
            scl_filt <= 1'b1;
        end else begin
            // 使用比较范围优化
            sda_filt <= (sda_sum >= THRESHOLD);
            scl_filt <= (scl_sum >= THRESHOLD);
        end
    end

    // 滤波后总线驱动 - 使用条件操作符提高清晰度
    assign sda = sda_oen ? 1'bz : sda_filt;
    assign scl = scl_oen ? 1'bz : scl_filt;
endmodule