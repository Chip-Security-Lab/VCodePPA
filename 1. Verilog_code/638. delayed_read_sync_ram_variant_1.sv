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
    output wire [DATA_WIDTH-1:0] dout
);
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] mem_out;
    reg [DATA_WIDTH-1:0] dout_reg;
    
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        mem_out <= ram[addr];
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_reg <= 0;
        end else begin
            dout_reg <= mem_out;
        end
    end
    
    assign dout = dout_reg;
endmodule