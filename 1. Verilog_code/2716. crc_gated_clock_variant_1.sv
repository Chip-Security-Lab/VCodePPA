//SystemVerilog
//==========================================================================
// 顶层模块：CRC计算器与门控时钟
//==========================================================================
module crc_gated_clock (
    input  wire       clk,       // 系统时钟
    input  wire       en,        // 使能信号
    input  wire [7:0] data,      // 输入数据
    output wire [15:0] crc       // CRC校验结果
);
    // 内部信号
    wire        gated_clk;       // 门控时钟
    wire [15:0] next_crc;        // 下一个CRC值
    reg  [15:0] crc_reg;         // CRC寄存器
    
    // 为高扇出信号添加缓冲
    wire clk_buf1, clk_buf2;     // 时钟缓冲信号
    wire en_buf1, en_buf2;       // 使能缓冲信号
    wire gated_clk_buf1, gated_clk_buf2;  // 门控时钟缓冲
    reg [15:0] next_crc_buf;     // CRC结果缓冲寄存器
    reg [15:0] current_crc_buf1, current_crc_buf2;  // 当前CRC缓冲信号

    // 时钟缓冲
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;

    // 使能信号缓冲
    assign en_buf1 = en;
    assign en_buf2 = en;

    // 门控时钟生成模块实例化 - 使用缓冲后的信号
    clock_gate clock_gate_inst (
        .clk      (clk_buf1),
        .en       (en_buf1),
        .gated_clk(gated_clk)
    );

    // 门控时钟缓冲
    assign gated_clk_buf1 = gated_clk;
    assign gated_clk_buf2 = gated_clk;

    // 当前CRC寄存器值缓冲
    always @(posedge clk_buf2) begin
        if (en_buf2) begin
            current_crc_buf1 <= crc_reg;
            current_crc_buf2 <= crc_reg;
        end
    end

    // CRC计算逻辑模块实例化 - 使用缓冲信号
    crc_calculator crc_calc_inst (
        .current_crc(current_crc_buf1),
        .data       (data),
        .next_crc   (next_crc)
    );

    // 缓冲next_crc以减少扇出负载
    always @(posedge clk_buf1) begin
        if (en_buf1) begin
            next_crc_buf <= next_crc;
        end
    end

    // 寄存器更新逻辑
    always @(posedge gated_clk_buf1) begin
        crc_reg <= next_crc_buf;
    end

    // 输出赋值
    assign crc = crc_reg;

endmodule

//==========================================================================
// 子模块：时钟门控单元
//==========================================================================
module clock_gate (
    input  wire clk,        // 系统时钟
    input  wire en,         // 使能信号
    output wire gated_clk   // 门控后的时钟
);
    // 带锁存器的时钟门控以避免毛刺，提高时序稳定性
    reg en_latch;
    
    always @(clk or en) begin
        if (!clk)
            en_latch <= en;
    end
    
    assign gated_clk = clk & en_latch;

endmodule

//==========================================================================
// 子模块：CRC计算单元
//==========================================================================
module crc_calculator (
    input  wire [15:0] current_crc,  // 当前CRC值
    input  wire [7:0]  data,         // 输入数据
    output wire [15:0] next_crc      // 计算后的CRC值
);
    // 常量定义
    localparam [15:0] CRC_POLYNOMIAL = 16'h8005;  // CRC多项式
    
    // 中间信号 - 拆分组合逻辑路径
    wire [15:0] shifted_crc;         // 移位后的CRC
    wire [15:0] polynomial_xor;      // 与多项式异或的结果
    wire [15:0] data_extended;       // 扩展后的数据
    wire poly_sel;                   // 多项式选择标志
    wire [15:0] poly_mask;           // 多项式掩码
    wire [15:0] data_xor_stage;      // 中间异或结果
    
    // 拆分计算步骤以减少关键路径深度
    assign poly_sel = current_crc[15];
    assign poly_mask = {16{poly_sel}} & CRC_POLYNOMIAL;  // 条件选择，减少逻辑深度
    assign shifted_crc = {current_crc[14:0], 1'b0};      // 左移1位
    assign data_extended = {8'h00, data};                // 数据扩展
    
    // 分阶段计算以减轻关键路径
    assign data_xor_stage = shifted_crc ^ poly_mask;     // 第一阶段异或
    assign next_crc = data_xor_stage ^ data_extended;    // 第二阶段异或

endmodule