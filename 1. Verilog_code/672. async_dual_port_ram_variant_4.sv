//SystemVerilog
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                    // 时钟信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,   // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,     // 数据输入
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,   // 数据输出
    input wire we_a, we_b,                        // 写使能信号
    input wire flush,                             // 流水线刷新信号
    output reg valid_a, valid_b                   // 输出有效信号
);

    // 内存阵列
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 流水线阶段1: 地址和数据锁存
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg valid_a_stage1, valid_b_stage1;
    
    // 流水线阶段2: 写操作和读操作准备
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg valid_a_stage2, valid_b_stage2;
    
    // 流水线阶段3: 读操作完成
    reg [DATA_WIDTH-1:0] dout_a_stage3, dout_b_stage3;
    reg valid_a_stage3, valid_b_stage3;

    // 流水线阶段1: 地址和数据锁存
    always @(posedge clk) begin
        if (flush) begin
            valid_a_stage1 <= 1'b0;
            valid_b_stage1 <= 1'b0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            valid_a_stage1 <= 1'b1;
            valid_b_stage1 <= 1'b1;
        end
    end

    // 流水线阶段2: 写操作和读操作准备
    always @(posedge clk) begin
        if (flush) begin
            valid_a_stage2 <= 1'b0;
            valid_b_stage2 <= 1'b0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            valid_a_stage2 <= valid_a_stage1;
            valid_b_stage2 <= valid_b_stage1;
            
            // 写操作
            if (we_a_stage1) begin
                ram[addr_a_stage1] <= din_a_stage1;
            end
            if (we_b_stage1) begin
                ram[addr_b_stage1] <= din_b_stage1;
            end
        end
    end

    // 流水线阶段3: 读操作完成
    always @(posedge clk) begin
        if (flush) begin
            valid_a_stage3 <= 1'b0;
            valid_b_stage3 <= 1'b0;
        end else begin
            dout_a_stage3 <= ram[addr_a_stage2];
            dout_b_stage3 <= ram[addr_b_stage2];
            valid_a_stage3 <= valid_a_stage2;
            valid_b_stage3 <= valid_b_stage2;
        end
    end

    // 输出赋值
    always @(posedge clk) begin
        dout_a <= dout_a_stage3;
        dout_b <= dout_b_stage3;
        valid_a <= valid_a_stage3;
        valid_b <= valid_b_stage3;
    end

endmodule