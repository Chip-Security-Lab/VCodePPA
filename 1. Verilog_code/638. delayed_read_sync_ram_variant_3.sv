//SystemVerilog
module delayed_read_sync_ram #(
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

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] dout_delayed;
    reg [DATA_WIDTH-1:0] ram_data;
    reg [DATA_WIDTH-1:0] ram_data_inv;
    reg [DATA_WIDTH-1:0] ram_data_sel;

    // 组合逻辑优化
    always @(*) begin
        ram_data = ram[addr];
        ram_data_inv = ~ram_data;
        ram_data_sel = (we) ? din : ram_data;
    end

    // 时序逻辑优化
    always @(posedge clk or posedge rst) begin
        dout <= (rst) ? {DATA_WIDTH{1'b0}} : dout_delayed;
        dout_delayed <= (rst) ? {DATA_WIDTH{1'b0}} : ram_data_sel;
        ram[addr] <= (rst) ? {DATA_WIDTH{1'b0}} : ((we) ? ram_data_sel : ram[addr]);
    end

endmodule