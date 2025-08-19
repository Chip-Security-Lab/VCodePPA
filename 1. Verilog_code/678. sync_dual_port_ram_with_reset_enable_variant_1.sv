//SystemVerilog
module sync_dual_port_ram_with_reset_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                            // 时钟信号
    input wire rst,                            // 复位信号
    input wire en,                             // 使能信号
    input wire we_a, we_b,                     // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 数据输出
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];  // 内存阵列
    reg [DATA_WIDTH-1:0] addr_a_reg, addr_b_reg;     // 地址寄存器
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;       // 数据输入寄存器
    reg we_a_reg, we_b_reg;                          // 写使能寄存器

    // 输入寄存器级
    always @(posedge clk) begin
        if (en) begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
        end
    end

    // 内存操作级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en) begin
            if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
            if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
            dout_a <= ram[addr_a_reg];
            dout_b <= ram[addr_b_reg];
        end
    end
endmodule

// 条件求和减法器模块
module conditional_sum_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] a,           // 被减数
    input wire [DATA_WIDTH-1:0] b,           // 减数
    output wire [DATA_WIDTH-1:0] diff,       // 差值
    output wire borrow                      // 借位
);

    // 条件求和减法算法实现
    wire [DATA_WIDTH-1:0] b_comp;            // 减数的补码
    wire [DATA_WIDTH-1:0] sum;               // 和
    wire [DATA_WIDTH:0] carry;               // 进位链
    
    // 计算减数的补码
    assign b_comp = ~b + 1'b1;
    
    // 条件求和减法
    assign {carry, sum} = a + b_comp;
    
    // 输出结果
    assign diff = sum;
    assign borrow = ~carry[DATA_WIDTH];
    
endmodule

// 集成条件求和减法器的RAM模块
module ram_with_subtractor #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                            // 时钟信号
    input wire rst,                            // 复位信号
    input wire en,                             // 使能信号
    input wire we_a, we_b,                     // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,   // 减法操作数
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, // 数据输出
    output wire [DATA_WIDTH-1:0] diff_a, diff_b, // 减法结果
    output wire borrow_a, borrow_b             // 借位信号
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];  // 内存阵列
    reg [DATA_WIDTH-1:0] addr_a_reg, addr_b_reg;     // 地址寄存器
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;       // 数据输入寄存器
    reg [DATA_WIDTH-1:0] sub_a_reg, sub_b_reg;       // 减法操作数寄存器
    reg we_a_reg, we_b_reg;                          // 写使能寄存器

    // 输入寄存器级
    always @(posedge clk) begin
        if (en) begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
            sub_a_reg <= sub_a;
            sub_b_reg <= sub_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
        end
    end

    // 内存操作级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en) begin
            if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
            if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
            dout_a <= ram[addr_a_reg];
            dout_b <= ram[addr_b_reg];
        end
    end
    
    // 实例化条件求和减法器
    conditional_sum_subtractor #(DATA_WIDTH) sub_a_inst (
        .a(dout_a),
        .b(sub_a_reg),
        .diff(diff_a),
        .borrow(borrow_a)
    );
    
    conditional_sum_subtractor #(DATA_WIDTH) sub_b_inst (
        .a(dout_b),
        .b(sub_b_reg),
        .diff(diff_b),
        .borrow(borrow_b)
    );
    
endmodule