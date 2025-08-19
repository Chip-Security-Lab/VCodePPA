//SystemVerilog
// SystemVerilog IEEE 1364-2005

// 顶层模块 - 双缓冲控制器
module int_ctrl_double_buf #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,      // 添加复位信号增强可靠性
    input                  swap,
    input      [WIDTH-1:0] new_status,
    output     [WIDTH-1:0] current_status
);

    // 内部信号
    wire [WIDTH-1:0] buffer_primary;
    wire [WIDTH-1:0] buffer_secondary;
    
    // 扇出缓冲信号
    (* dont_touch = "true" *) reg clk_buf1, clk_buf2;
    (* dont_touch = "true" *) reg [WIDTH-1:0] width_buf1, width_buf2;
    (* dont_touch = "true" *) reg [WIDTH-1:0] new_status_buf1, new_status_buf2;
    (* dont_touch = "true" *) reg [WIDTH-1:0] buffer_primary_buf1, buffer_primary_buf2;
    
    // 时钟缓冲
    always @(posedge clk) begin
        clk_buf1 <= 1'b1;
        clk_buf2 <= 1'b1;
    end
    
    // WIDTH参数缓冲 (编译时常量缓冲)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            width_buf1 <= WIDTH;
            width_buf2 <= WIDTH;
        end else begin
            width_buf1 <= WIDTH;
            width_buf2 <= WIDTH;
        end
    end
    
    // new_status缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            new_status_buf1 <= {WIDTH{1'b0}};
            new_status_buf2 <= {WIDTH{1'b0}};
        end else begin
            new_status_buf1 <= new_status;
            new_status_buf2 <= new_status;
        end
    end
    
    // buffer_primary缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_primary_buf1 <= {WIDTH{1'b0}};
            buffer_primary_buf2 <= {WIDTH{1'b0}};
        end else begin
            buffer_primary_buf1 <= buffer_primary;
            buffer_primary_buf2 <= buffer_primary;
        end
    end
    
    // 缓冲区管理模块
    buffer_manager #(
        .WIDTH(WIDTH)
    ) u_buffer_manager (
        .clk              (clk),
        .rst_n            (rst_n),
        .swap             (swap),
        .new_status       (new_status_buf1),
        .buffer_primary   (buffer_primary),
        .buffer_secondary (buffer_secondary)
    );
    
    // 状态输出模块
    status_output #(
        .WIDTH(WIDTH)
    ) u_status_output (
        .buffer_primary   (buffer_primary_buf1),
        .current_status   (current_status)
    );

endmodule

// 缓冲区管理模块 - 处理双缓冲区的数据更新
module buffer_manager #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  swap,
    input      [WIDTH-1:0] new_status,
    output reg [WIDTH-1:0] buffer_primary,
    output reg [WIDTH-1:0] buffer_secondary
);

    // 扇出缓冲器
    (* dont_touch = "true" *) reg [WIDTH-1:0] new_status_buf;
    (* dont_touch = "true" *) reg [WIDTH-1:0] buffer_primary_internal;
    (* dont_touch = "true" *) reg swap_buf;
    
    // 输入缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            new_status_buf <= {WIDTH{1'b0}};
            swap_buf <= 1'b0;
        end else begin
            new_status_buf <= new_status;
            swap_buf <= swap;
        end
    end

    // 二级缓冲区更新 - 始终更新二级缓冲区
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_secondary <= {WIDTH{1'b0}};
        end else begin
            buffer_secondary <= new_status_buf;
        end
    end

    // 主缓冲区更新 - 仅在swap信号有效时更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_primary_internal <= {WIDTH{1'b0}};
        end else if (swap_buf) begin
            buffer_primary_internal <= buffer_secondary;
        end
    end
    
    // 缓冲输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_primary <= {WIDTH{1'b0}};
        end else begin
            buffer_primary <= buffer_primary_internal;
        end
    end

endmodule

// 状态输出模块 - 从主缓冲区输出状态
module status_output #(
    parameter WIDTH = 8
)(
    input      [WIDTH-1:0] buffer_primary,
    output reg [WIDTH-1:0] current_status
);

    // 添加寄存器缓冲减少扇出负载
    always @(*) begin
        current_status = buffer_primary;
    end

endmodule