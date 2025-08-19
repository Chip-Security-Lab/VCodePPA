//SystemVerilog
// 顶层模块
module sync_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // 内部信号
    wire [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    wire we_a_stage1, we_b_stage1;
    wire [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    
    wire [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    wire we_a_stage2, we_b_stage2;
    wire [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    wire [DATA_WIDTH-1:0] dout_a_stage2, dout_b_stage2;

    // 实例化流水线阶段模块
    pipeline_stage1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) stage1 (
        .clk(clk),
        .rst(rst),
        .addr_a_in(addr_a),
        .addr_b_in(addr_b),
        .we_a_in(we_a),
        .we_b_in(we_b),
        .din_a_in(din_a),
        .din_b_in(din_b),
        .addr_a_out(addr_a_stage1),
        .addr_b_out(addr_b_stage1),
        .we_a_out(we_a_stage1),
        .we_b_out(we_b_stage1),
        .din_a_out(din_a_stage1),
        .din_b_out(din_b_stage1)
    );

    pipeline_stage2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) stage2 (
        .clk(clk),
        .rst(rst),
        .addr_a_in(addr_a_stage1),
        .addr_b_in(addr_b_stage1),
        .we_a_in(we_a_stage1),
        .we_b_in(we_b_stage1),
        .din_a_in(din_a_stage1),
        .din_b_in(din_b_stage1),
        .addr_a_out(addr_a_stage2),
        .addr_b_out(addr_b_stage2),
        .we_a_out(we_a_stage2),
        .we_b_out(we_b_stage2),
        .din_a_out(din_a_stage2),
        .din_b_out(din_b_stage2),
        .dout_a(dout_a_stage2),
        .dout_b(dout_b_stage2)
    );

    pipeline_stage3 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) stage3 (
        .clk(clk),
        .rst(rst),
        .dout_a_in(dout_a_stage2),
        .dout_b_in(dout_b_stage2),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );

endmodule

// 第一级流水线模块
module pipeline_stage1 #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] addr_a_in, addr_b_in,
    input wire we_a_in, we_b_in,
    input wire [DATA_WIDTH-1:0] din_a_in, din_b_in,
    output reg [ADDR_WIDTH-1:0] addr_a_out, addr_b_out,
    output reg we_a_out, we_b_out,
    output reg [DATA_WIDTH-1:0] din_a_out, din_b_out
);

    // 地址流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_out <= 0;
            addr_b_out <= 0;
        end else begin
            addr_a_out <= addr_a_in;
            addr_b_out <= addr_b_in;
        end
    end

    // 写使能流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_a_out <= 0;
            we_b_out <= 0;
        end else begin
            we_a_out <= we_a_in;
            we_b_out <= we_b_in;
        end
    end

    // 数据输入流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_out <= 0;
            din_b_out <= 0;
        end else begin
            din_a_out <= din_a_in;
            din_b_out <= din_b_in;
        end
    end

endmodule

// 第二级流水线模块
module pipeline_stage2 #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] addr_a_in, addr_b_in,
    input wire we_a_in, we_b_in,
    input wire [DATA_WIDTH-1:0] din_a_in, din_b_in,
    output reg [ADDR_WIDTH-1:0] addr_a_out, addr_b_out,
    output reg we_a_out, we_b_out,
    output reg [DATA_WIDTH-1:0] din_a_out, din_b_out,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // 地址流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_out <= 0;
            addr_b_out <= 0;
        end else begin
            addr_a_out <= addr_a_in;
            addr_b_out <= addr_b_in;
        end
    end

    // 写使能流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_a_out <= 0;
            we_b_out <= 0;
        end else begin
            we_a_out <= we_a_in;
            we_b_out <= we_b_in;
        end
    end

    // 数据输入流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_out <= 0;
            din_b_out <= 0;
        end else begin
            din_a_out <= din_a_in;
            din_b_out <= din_b_in;
        end
    end

    // 数据输出流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram[addr_a_in];
            dout_b <= ram[addr_b_in];
        end
    end

    // RAM写入逻辑
    always @(posedge clk) begin
        if (we_a_in) ram[addr_a_in] <= din_a_in;
        if (we_b_in) ram[addr_b_in] <= din_b_in;
    end

endmodule

// 第三级流水线模块
module pipeline_stage3 #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] dout_a_in, dout_b_in,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // 数据输出流水线寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= dout_a_in;
            dout_b <= dout_b_in;
        end
    end

endmodule