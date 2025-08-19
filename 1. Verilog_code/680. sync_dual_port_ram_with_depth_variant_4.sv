//SystemVerilog
// 查找表辅助减法器模块
module lut_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] a,
    input wire [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] diff
);

    reg [DATA_WIDTH-1:0] lut [0:255];
    reg [DATA_WIDTH-1:0] b_comp;
    reg [DATA_WIDTH-1:0] sum;

    // 初始化查找表
    initial begin
        for (int i = 0; i < 256; i++) begin
            lut[i] = i;
        end
    end

    always @(*) begin
        b_comp = ~b + 1'b1;
        sum = a + b_comp;
        diff = lut[sum];
    end
endmodule

// 内存核心模块
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    wire [DATA_WIDTH-1:0] addr_diff;

    lut_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) addr_sub (
        .a(addr),
        .b(8'd1),
        .diff(addr_diff)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            if (we) ram[addr] <= din;
            dout <= ram[addr_diff];
        end
    end
endmodule

// 端口控制模块
module port_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    wire [DATA_WIDTH-1:0] ram_dout;

    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .clk(clk),
        .rst(rst),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(ram_dout)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            dout <= ram_dout;
        end
    end
endmodule

// 顶层双端口RAM模块
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
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);

    port_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_a (
        .clk(clk),
        .rst(rst),
        .we(we_a),
        .addr(addr_a),
        .din(din_a),
        .dout(dout_a)
    );

    port_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_b (
        .clk(clk),
        .rst(rst),
        .we(we_b),
        .addr(addr_b),
        .din(din_b),
        .dout(dout_b)
    );
endmodule