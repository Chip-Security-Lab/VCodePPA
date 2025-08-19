//SystemVerilog
module shadow_reg #(
    parameter DW = 16
)(
    input  wire           clk,
    input  wire           en,
    input  wire           commit,
    input  wire [DW-1:0]  din,
    output wire [DW-1:0]  dout
);
    wire           commit_d;
    wire [DW-1:0]  working_reg;
    
    // 实例化数据捕获子模块
    data_capture #(
        .DW(DW)
    ) u_data_capture (
        .clk         (clk),
        .en          (en),
        .din         (din),
        .working_reg (working_reg)
    );
    
    // 实例化提交控制子模块
    commit_control u_commit_control (
        .clk       (clk),
        .commit    (commit),
        .commit_d  (commit_d)
    );
    
    // 实例化输出寄存器子模块
    output_register #(
        .DW(DW)
    ) u_output_register (
        .clk         (clk),
        .commit_d    (commit_d),
        .working_reg (working_reg),
        .dout        (dout)
    );
    
endmodule

// 数据捕获子模块 - 负责在使能时捕获输入数据
module data_capture #(
    parameter DW = 16
)(
    input  wire           clk,
    input  wire           en,
    input  wire [DW-1:0]  din,
    output reg  [DW-1:0]  working_reg
);
    always @(posedge clk) begin
        if (en) begin
            working_reg <= din;
        end
    end
endmodule

// 提交控制子模块 - 负责提交信号的时序控制
module commit_control (
    input  wire  clk,
    input  wire  commit,
    output reg   commit_d
);
    always @(posedge clk) begin
        commit_d <= commit;
    end
endmodule

// 输出寄存器子模块 - 负责在提交信号有效时更新输出
module output_register #(
    parameter DW = 16
)(
    input  wire           clk,
    input  wire           commit_d,
    input  wire [DW-1:0]  working_reg,
    output reg  [DW-1:0]  dout
);
    always @(posedge clk) begin
        if (commit_d) begin
            dout <= working_reg;
        end
    end
endmodule