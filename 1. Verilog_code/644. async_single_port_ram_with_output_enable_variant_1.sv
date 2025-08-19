//SystemVerilog
module async_single_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire oe
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] temp_data;
    reg [DATA_WIDTH-1:0] inverted_data;
    reg [DATA_WIDTH-1:0] result;

    always @* begin
        if (we) begin
            temp_data = din;
            inverted_data = ~temp_data;
            if (temp_data[DATA_WIDTH-1]) begin
                result = inverted_data;
            end else begin
                result = temp_data;
            end
            ram[addr] = result;
        end
        
        if (oe) begin
            dout = ram[addr];
        end
    end
endmodule