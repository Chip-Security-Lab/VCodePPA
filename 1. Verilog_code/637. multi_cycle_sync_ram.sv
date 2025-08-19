module multi_cycle_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter CYCLE_COUNT = 3  // 输出周期
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [1:0] cycle_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            cycle_counter <= 0;
        end else if (we) begin
            ram[addr] <= din;
            cycle_counter <= 0;
        end else if (cycle_counter < CYCLE_COUNT) begin
            cycle_counter <= cycle_counter + 1;
        end else begin
            dout <= ram[addr];
        end
    end
endmodule
