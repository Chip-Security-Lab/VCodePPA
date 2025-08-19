//SystemVerilog
module rom_parity #(parameter BITS=12)(
    input wire clk,                  // 添加时钟输入以支持流水线
    input wire rst_n,                // 添加复位信号
    input wire [7:0] addr,           // 地址输入
    input wire req_valid,            // 请求有效信号
    output reg resp_valid,           // 响应有效信号
    output reg [BITS-1:0] data       // 数据输出
);
    // 内存声明
    reg [BITS-2:0] mem [0:255];
    
    // 示例初始化
    initial begin
        // 将一些示例值设置为具体值用于综合
        mem[0] = 11'b10101010101;
        mem[1] = 11'b01010101010;
        // $readmemb("parity_data.bin", mem); // 仿真中使用
    end
    
    // 流水线阶段 1: 地址寄存与请求
    reg [7:0] addr_r;
    reg req_valid_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            addr_r <= 8'b0;
            req_valid_r <= 1'b0;
        end else begin
            addr_r <= addr;
            req_valid_r <= req_valid;
        end
    end
    
    // 流水线阶段 2: 存储器访问
    reg [BITS-2:0] mem_data_r;
    reg stage2_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            mem_data_r <= {(BITS-1){1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            if (req_valid_r) begin
                mem_data_r <= mem[addr_r];
            end
            stage2_valid <= req_valid_r;
        end
    end
    
    // 流水线阶段 3: 奇偶校验计算与结果组装
    wire parity_bit;
    
    // 使用模块化的奇偶校验计算器 - 分层设计
    parity_calculator #(
        .WIDTH(BITS-1)
    ) parity_gen (
        .data_in(mem_data_r),
        .parity_out(parity_bit)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data <= {BITS{1'b0}};
            resp_valid <= 1'b0;
        end else begin
            if (stage2_valid) begin
                data <= {parity_bit, mem_data_r};
            end
            resp_valid <= stage2_valid;
        end
    end
endmodule

// 模块化奇偶校验计算器
module parity_calculator #(
    parameter WIDTH = 11
)(
    input wire [WIDTH-1:0] data_in,
    output wire parity_out
);
    // 分块计算奇偶校验以减少逻辑深度
    wire [3:0] parity_blocks;
    
    // 将数据分成4个块进行并行计算
    assign parity_blocks[0] = ^data_in[WIDTH/4-1:0];
    assign parity_blocks[1] = ^data_in[WIDTH/2-1:WIDTH/4];
    assign parity_blocks[2] = ^data_in[3*WIDTH/4-1:WIDTH/2];
    assign parity_blocks[3] = ^data_in[WIDTH-1:3*WIDTH/4];
    
    // 合并块级奇偶校验结果
    assign parity_out = ^parity_blocks;
endmodule