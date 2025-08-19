//SystemVerilog
// 顶层模块：将整体功能分解为多个子模块
module activity_clock_gate (
    input  wire        clk_in,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire [7:0]  prev_data,
    input  wire        valid_in,
    output wire        valid_out,
    output wire        clk_out
);
    // 内部连线声明
    wire [7:0]  data_in_registered;
    wire [7:0]  prev_data_registered;
    wire        valid_stage1;
    
    wire [7:0]  data_diff;
    wire        valid_stage2;
    
    wire        activity_detected;
    wire        valid_stage3;
    
    wire        gating_control;

    // 实例化输入寄存子模块
    input_register input_reg_inst (
        .clk          (clk_in),
        .rst_n        (rst_n),
        .data_in      (data_in),
        .prev_data    (prev_data),
        .valid_in     (valid_in),
        .data_out     (data_in_registered),
        .prev_data_out(prev_data_registered),
        .valid_out    (valid_stage1)
    );
    
    // 实例化数据差异计算子模块
    data_difference diff_calculator (
        .clk          (clk_in),
        .rst_n        (rst_n),
        .data_in      (data_in_registered),
        .prev_data    (prev_data_registered),
        .valid_in     (valid_stage1),
        .data_diff    (data_diff),
        .valid_out    (valid_stage2)
    );
    
    // 实例化活动检测子模块
    activity_detector act_detector (
        .clk              (clk_in),
        .rst_n            (rst_n),
        .data_diff        (data_diff),
        .valid_in         (valid_stage2),
        .activity_detected(activity_detected),
        .valid_out        (valid_stage3)
    );
    
    // 实例化时钟门控控制子模块
    clock_gating_control gating_ctrl (
        .clk          (clk_in),
        .rst_n        (rst_n),
        .activity_in  (activity_detected),
        .valid_in     (valid_stage3),
        .gating_control(gating_control),
        .valid_out    (valid_out)
    );
    
    // 时钟输出门控
    assign clk_out = clk_in & gating_control;
    
endmodule

// 子模块1：输入寄存模块
module input_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire [7:0]  prev_data,
    input  wire        valid_in,
    output reg  [7:0]  data_out,
    output reg  [7:0]  prev_data_out,
    output reg         valid_out
);
    // 第1级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out     <= 8'h0;
            prev_data_out <= 8'h0;
            valid_out    <= 1'b0;
        end else begin
            data_out     <= data_in;
            prev_data_out <= prev_data;
            valid_out    <= valid_in;
        end
    end
endmodule

// 子模块2：数据差异计算模块
module data_difference (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire [7:0]  prev_data,
    input  wire        valid_in,
    output reg  [7:0]  data_diff,
    output reg         valid_out
);
    // 第2级：计算数据差异
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_diff <= 8'h0;
            valid_out <= 1'b0;
        end else begin
            data_diff <= data_in ^ prev_data;
            valid_out <= valid_in;
        end
    end
endmodule

// 子模块3：活动检测模块
module activity_detector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_diff,
    input  wire        valid_in,
    output reg         activity_detected,
    output reg         valid_out
);
    // 第3级：检测任何位的变化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activity_detected <= 1'b0;
            valid_out         <= 1'b0;
        end else begin
            activity_detected <= |data_diff;
            valid_out         <= valid_in;
        end
    end
endmodule

// 子模块4：时钟门控控制模块
module clock_gating_control (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        activity_in,
    input  wire        valid_in,
    output reg         gating_control,
    output reg         valid_out
);
    // 第4级：时钟控制生成（负边沿触发）
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gating_control <= 1'b0;
            valid_out      <= 1'b0;
        end else begin
            gating_control <= activity_in;
            valid_out      <= valid_in;
        end
    end
endmodule