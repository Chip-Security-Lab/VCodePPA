//SystemVerilog
module sync_priority_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,               
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, 
    input wire [DATA_WIDTH-1:0] din_a, din_b,   
    output reg [DATA_WIDTH-1:0] dout     
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_buf;
    reg [ADDR_WIDTH-1:0] addr_buf;
    reg we_buf;
    reg [DATA_WIDTH-1:0] din_buf;
    wire write_enable;
    wire [ADDR_WIDTH-1:0] write_addr;
    wire [DATA_WIDTH-1:0] write_data;

    assign write_enable = we_a | we_b;
    assign write_addr = we_a ? addr_a : addr_b;
    assign write_data = we_a ? din_a : din_b;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_buf <= 0;
            addr_buf <= 0;
            we_buf <= 0;
            din_buf <= 0;
            dout <= 0;
        end else begin
            if (write_enable) begin
                ram_buf <= write_data;
                addr_buf <= write_addr;
                we_buf <= 1'b1;
                din_buf <= write_data;
                dout <= ram[write_addr];
            end else begin
                we_buf <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (we_buf) begin
            ram[addr_buf] <= ram_buf;
        end
    end

endmodule