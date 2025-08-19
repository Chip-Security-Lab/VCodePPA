//SystemVerilog
// 顶层模块
module nonlinear_quant #(
    parameter IN_W = 8,
    parameter OUT_W = 4,
    parameter LUT_SIZE = 16,
    parameter PIPELINE_STAGES = 2
)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire [IN_W-1:0] data_in,
    input wire data_valid,  // 添加数据有效信号
    output wire [OUT_W-1:0] quant_out,
    output wire quant_valid  // 添加输出有效信号
);
    // 内部数据流信号
    wire [$clog2(LUT_SIZE)-1:0] lut_addr_stage1;
    reg  [$clog2(LUT_SIZE)-1:0] lut_addr_stage2;
    reg  [PIPELINE_STAGES-1:0] valid_pipeline;
    
    // 数据流管道第一阶段 - 地址生成
    lut_addr_gen #(
        .IN_W(IN_W),
        .LUT_SIZE(LUT_SIZE)
    ) u_addr_gen_stage (
        .data_in(data_in),
        .lut_addr(lut_addr_stage1)
    );
    
    // 数据流管道第二阶段 - 管道寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_addr_stage2 <= 0;
            valid_pipeline <= 0;
        end else begin
            lut_addr_stage2 <= lut_addr_stage1;
            valid_pipeline <= {valid_pipeline[PIPELINE_STAGES-2:0], data_valid};
        end
    end
    
    // 数据流管道第三阶段 - LUT查找
    lut_memory #(
        .LUT_SIZE(LUT_SIZE),
        .OUT_W(OUT_W),
        .IN_W(IN_W)
    ) u_lut_stage (
        .clk(clk),
        .rst_n(rst_n),
        .addr(lut_addr_stage2),
        .data_out(quant_out)
    );
    
    // 输出有效信号
    assign quant_valid = valid_pipeline[PIPELINE_STAGES-1];
    
endmodule

// 地址生成模块 - 优化数据路径第一阶段
module lut_addr_gen #(
    parameter IN_W = 8,
    parameter LUT_SIZE = 16
)(
    input wire [IN_W-1:0] data_in,
    output wire [$clog2(LUT_SIZE)-1:0] lut_addr
);
    // 实现高效的地址提取方式
    localparam ADDR_WIDTH = $clog2(LUT_SIZE);
    
    // 添加明确的位提取逻辑，使数据路径更清晰
    wire [ADDR_WIDTH-1:0] extracted_bits;
    assign extracted_bits = data_in[IN_W-1:IN_W-ADDR_WIDTH];
    
    // 地址输出
    assign lut_addr = extracted_bits;
endmodule

// LUT存储模块 - 优化数据路径第三阶段
module lut_memory #(
    parameter LUT_SIZE = 16,
    parameter OUT_W = 4,
    parameter IN_W = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [$clog2(LUT_SIZE)-1:0] addr,
    output reg [OUT_W-1:0] data_out
);
    // 定义LUT存储
    reg [OUT_W-1:0] lut_table [0:LUT_SIZE-1];
    
    // 分离LUT初始化逻辑，提高可读性
    initial begin
        integer i;
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            // 非线性映射函数 - 使用平方运算
            lut_table[i] = ((i*i) >> (IN_W - OUT_W));
        end
    end
    
    // 优化LUT读取逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUT_W{1'b0}};
        end else begin
            data_out <= lut_table[addr];
        end
    end
endmodule