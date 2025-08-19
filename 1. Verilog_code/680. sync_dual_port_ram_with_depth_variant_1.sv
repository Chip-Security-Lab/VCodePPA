//SystemVerilog
module sync_dual_port_ram_with_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    // 新增减法器接口
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,
    output reg [DATA_WIDTH-1:0] sub_result
);

    // 实例化内存阵列模块
    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_DEPTH(RAM_DEPTH)
    ) ram_array_inst (
        .clk(clk),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .we_a(we_a),
        .we_b(we_b),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );

    // 实例化先行借位减法器
    carry_lookahead_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) subtractor_inst (
        .a(sub_a),
        .b(sub_b),
        .result(sub_result)
    );

endmodule

// 内存阵列子模块
module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    // 端口A操作
    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
        end
        dout_a <= ram[addr_a];
    end

    // 端口B操作
    always @(posedge clk) begin
        if (we_b) begin
            ram[addr_b] <= din_b;
        end
        dout_b <= ram[addr_b];
    end

endmodule

// 先行借位减法器模块
module carry_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [WIDTH-1:0] result
);

    // 生成和传播信号
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] borrow;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_propagate
            assign g[i] = a[i] & ~b[i];  // 生成信号
            assign p[i] = a[i] ^ ~b[i];  // 传播信号
        end
    endgenerate
    
    // 计算借位信号
    assign borrow[0] = 1'b1;  // 初始借位为1
    genvar j;
    generate
        for (j = 1; j <= WIDTH; j = j + 1) begin : gen_borrow
            assign borrow[j] = g[j-1] | (p[j-1] & borrow[j-1]);
        end
    endgenerate
    
    // 计算减法结果
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin : gen_result
            always @(*) begin
                result[k] = a[k] ^ ~b[k] ^ borrow[k];
            end
        end
    endgenerate

endmodule