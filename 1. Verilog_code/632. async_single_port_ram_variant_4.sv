//SystemVerilog
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] borrow;
    reg [DATA_WIDTH-1:0] temp_result;
    integer i;
    
    always @(addr or we or din) begin
        if (we) begin
            borrow = 0;
            i = 0;
            while (i < DATA_WIDTH) begin
                temp_result[i] = din[i] ^ borrow;
                borrow = (~din[i] & borrow) | (din[i] & ~borrow);
                i = i + 1;
            end
            ram[addr] = temp_result;
        end
        dout = ram[addr];
    end
endmodule