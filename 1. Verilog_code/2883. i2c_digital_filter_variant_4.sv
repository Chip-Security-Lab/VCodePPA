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
    // 可配置数字滤波
    reg [FILTER_DEPTH-1:0] sda_history;
    reg [FILTER_DEPTH-1:0] scl_history;
    
    reg [2:0] sda_sum; // 用于计数1的数量
    reg [2:0] scl_sum; // 用于计数1的数量
    
    // 条件求和信号声明
    wire sda_add_cond, sda_sub_cond;
    wire scl_add_cond, scl_sub_cond;
    wire [2:0] sda_sum_next;
    wire [2:0] scl_sum_next;
    
    // 确定何时添加或减去
    assign sda_add_cond = sda_raw;
    assign sda_sub_cond = sda_history[FILTER_DEPTH-1];
    assign scl_add_cond = scl_raw;
    assign scl_sub_cond = scl_history[FILTER_DEPTH-1];
    
    // 条件求和减法实现
    assign sda_sum_next = sda_sum + sda_add_cond - sda_sub_cond;
    assign scl_sum_next = scl_sum + scl_add_cond - scl_sub_cond;

    // SDA历史寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_history <= {FILTER_DEPTH{1'b1}};
        end else begin
            sda_history <= {sda_history[FILTER_DEPTH-2:0], sda_raw};
        end
    end
    
    // SCL历史寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_history <= {FILTER_DEPTH{1'b1}};
        end else begin
            scl_history <= {scl_history[FILTER_DEPTH-2:0], scl_raw};
        end
    end
    
    // SDA总和寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sum <= FILTER_DEPTH;
        end else begin
            sda_sum <= sda_sum_next;
        end
    end
    
    // SCL总和寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_sum <= FILTER_DEPTH;
        end else begin
            scl_sum <= scl_sum_next;
        end
    end
    
    // SDA阈值过滤处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_filt <= 1'b1;
        end else begin
            sda_filt <= (sda_sum_next >= THRESHOLD) ? 1'b1 : 1'b0;
        end
    end
    
    // SCL阈值过滤处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_filt <= 1'b1;
        end else begin
            scl_filt <= (scl_sum_next >= THRESHOLD) ? 1'b1 : 1'b0;
        end
    end

    // 滤波后总线驱动
    assign sda = (sda_oen) ? 1'bz : sda_filt;
    assign scl = (scl_oen) ? 1'bz : scl_filt;
endmodule