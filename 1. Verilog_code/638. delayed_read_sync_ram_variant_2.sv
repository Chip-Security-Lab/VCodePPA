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
    reg [DATA_WIDTH-1:0] ram_read_data;
    reg [DATA_WIDTH-1:0] dout_stage1;
    reg [DATA_WIDTH-1:0] dout_stage2;
    reg [DATA_WIDTH-1:0] dout_stage3;

    // RAM write operation
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
    end

    // RAM read operation
    always @(posedge clk) begin
        ram_read_data <= ram[addr];
    end

    // Enhanced pipeline stages
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_stage1 <= 0;
            dout_stage2 <= 0;
            dout_stage3 <= 0;
            dout <= 0;
        end else begin
            dout_stage1 <= ram_read_data;
            dout_stage2 <= dout_stage1;
            dout_stage3 <= dout_stage2;
            dout <= dout_stage3;
        end
    end

endmodule