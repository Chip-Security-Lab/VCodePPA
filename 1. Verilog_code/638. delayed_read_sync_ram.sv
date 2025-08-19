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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            dout_delayed <= 0;
        end else begin
            if (we) ram[addr] <= din;
            dout_delayed <= ram[addr];
            dout <= dout_delayed;  // 输出延迟的数据
        end
    end
endmodule
