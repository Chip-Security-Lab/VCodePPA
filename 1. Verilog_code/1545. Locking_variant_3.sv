//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////

// 顶层模块
module locking_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire lock_req,
    input wire unlock_req,
    input wire capture,
    output wire [WIDTH-1:0] shadow_data,
    output wire locked
);
    // 内部信号
    wire [WIDTH-1:0] main_reg_data;
    
    // 主寄存器子模块实例化
    main_register #(
        .WIDTH(WIDTH)
    ) u_main_register (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .main_reg_out(main_reg_data)
    );
    
    // 锁控制子模块实例化
    lock_controller u_lock_controller (
        .clk(clk),
        .rst_n(rst_n),
        .lock_req(lock_req),
        .unlock_req(unlock_req),
        .locked(locked)
    );
    
    // 影子寄存器子模块实例化
    shadow_register #(
        .WIDTH(WIDTH)
    ) u_shadow_register (
        .clk(clk),
        .rst_n(rst_n),
        .main_reg_data(main_reg_data),
        .locked(locked),
        .capture(capture),
        .shadow_data(shadow_data)
    );
    
endmodule

// 主寄存器子模块
module main_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] main_reg_out
);
    // 主寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_out <= {WIDTH{1'b0}};
        else
            main_reg_out <= data_in;
    end
endmodule

// 锁控制器子模块
module lock_controller (
    input wire clk,
    input wire rst_n,
    input wire lock_req,
    input wire unlock_req,
    output reg locked
);
    // 锁控制逻辑 - 使用case语句代替if-else级联
    reg [1:0] lock_ctrl;
    
    always @(*) begin
        lock_ctrl = {lock_req, unlock_req};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            locked <= 1'b0;
        else begin
            case (lock_ctrl)
                2'b10:   locked <= 1'b1;  // 加锁请求
                2'b01:   locked <= 1'b0;  // 解锁请求
                default: locked <= locked; // 保持当前状态
            endcase
        end
    end
endmodule

// 影子寄存器子模块
module shadow_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] main_reg_data,
    input wire locked,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data
);
    // 影子寄存器更新逻辑 - 使用case语句代替if-else结构
    reg [1:0] shadow_ctrl;
    
    always @(*) begin
        shadow_ctrl = {capture, locked};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else begin
            case (shadow_ctrl)
                2'b10:   shadow_data <= main_reg_data;  // 捕获且未锁定
                default: shadow_data <= shadow_data;    // 其他情况保持不变
            endcase
        end
    end
endmodule