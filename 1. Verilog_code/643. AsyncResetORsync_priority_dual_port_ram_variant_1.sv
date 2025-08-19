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
    reg [DATA_WIDTH-1:0] read_data_a, read_data_b;
    reg write_done;

    // RAM读操作
    always @(posedge clk) begin
        read_data_a <= ram[addr_a];
        read_data_b <= ram[addr_b];
    end

    // RAM写操作
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= din_a;
        if (we_b) ram[addr_b] <= din_b;
    end

    // 输出数据选择
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= read_data_a;
            dout_b <= read_data_b;
        end
    end

endmodule