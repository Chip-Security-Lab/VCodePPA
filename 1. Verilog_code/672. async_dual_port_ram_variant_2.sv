//SystemVerilog
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg1, addr_b_reg1;
    reg [ADDR_WIDTH-1:0] addr_a_reg2, addr_b_reg2;
    reg [ADDR_WIDTH-1:0] addr_a_reg3, addr_b_reg3;
    reg [DATA_WIDTH-1:0] din_a_reg1, din_b_reg1;
    reg [DATA_WIDTH-1:0] din_a_reg2, din_b_reg2;
    reg [DATA_WIDTH-1:0] din_a_reg3, din_b_reg3;
    reg we_a_reg1, we_b_reg1;
    reg we_a_reg2, we_b_reg2;
    reg we_a_reg3, we_b_reg3;
    reg [DATA_WIDTH-1:0] ram_out_a_reg1, ram_out_b_reg1;
    reg [DATA_WIDTH-1:0] ram_out_a_reg2, ram_out_b_reg2;

    // 第一级流水线：输入寄存器
    always @(posedge clk) begin
        addr_a_reg1 <= addr_a;
        addr_b_reg1 <= addr_b;
        din_a_reg1 <= din_a;
        din_b_reg1 <= din_b;
        we_a_reg1 <= we_a;
        we_b_reg1 <= we_b;
    end

    // 第二级流水线：地址和数据寄存器
    always @(posedge clk) begin
        addr_a_reg2 <= addr_a_reg1;
        addr_b_reg2 <= addr_b_reg1;
        din_a_reg2 <= din_a_reg1;
        din_b_reg2 <= din_b_reg1;
        we_a_reg2 <= we_a_reg1;
        we_b_reg2 <= we_b_reg1;
    end

    // 第三级流水线：地址和数据寄存器
    always @(posedge clk) begin
        addr_a_reg3 <= addr_a_reg2;
        addr_b_reg3 <= addr_b_reg2;
        din_a_reg3 <= din_a_reg2;
        din_b_reg3 <= din_b_reg2;
        we_a_reg3 <= we_a_reg2;
        we_b_reg3 <= we_b_reg2;
    end

    // 写操作流水线级
    always @(posedge clk) begin
        if (we_a_reg3) ram[addr_a_reg3] <= din_a_reg3;
        if (we_b_reg3) ram[addr_b_reg3] <= din_b_reg3;
    end

    // 读操作第一级流水线
    always @(posedge clk) begin
        ram_out_a_reg1 <= ram[addr_a_reg3];
        ram_out_b_reg1 <= ram[addr_b_reg3];
    end

    // 读操作第二级流水线
    always @(posedge clk) begin
        ram_out_a_reg2 <= ram_out_a_reg1;
        ram_out_b_reg2 <= ram_out_b_reg1;
    end

    // 输出寄存器级
    always @(posedge clk) begin
        dout_a <= ram_out_a_reg2;
        dout_b <= ram_out_b_reg2;
    end

endmodule