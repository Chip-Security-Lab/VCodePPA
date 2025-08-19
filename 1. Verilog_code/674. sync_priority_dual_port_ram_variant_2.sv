//SystemVerilog
module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout_a, next_dout_b;
    reg [DATA_WIDTH-1:0] next_ram_a, next_ram_b;
    reg next_we_a, next_we_b;
    wire [DATA_WIDTH-1:0] twos_comp_a, twos_comp_b;
    wire [DATA_WIDTH-1:0] sub_result_a, sub_result_b;

    // 二进制补码减法器
    assign twos_comp_a = ~din_a + 1'b1;
    assign twos_comp_b = ~din_b + 1'b1;
    assign sub_result_a = ram[addr_a] + twos_comp_a;
    assign sub_result_b = ram[addr_b] + twos_comp_b;

    // 组合逻辑计算下一状态
    always @(*) begin
        next_we_a = we_a;
        next_we_b = we_b;
        
        if (read_first) begin
            next_dout_a = ram[addr_a];
            next_dout_b = ram[addr_b];
            next_ram_a = we_a ? sub_result_a : ram[addr_a];
            next_ram_b = we_b ? sub_result_b : ram[addr_b];
        end else begin
            next_ram_a = we_a ? sub_result_a : ram[addr_a];
            next_ram_b = we_b ? sub_result_b : ram[addr_b];
            next_dout_a = next_ram_a;
            next_dout_b = next_ram_b;
        end
    end

    // 时序逻辑更新状态
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= next_dout_a;
            dout_b <= next_dout_b;
            if (next_we_a) ram[addr_a] <= next_ram_a;
            if (next_we_b) ram[addr_b] <= next_ram_b;
        end
    end

endmodule