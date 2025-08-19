//SystemVerilog
module async_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire en_a, en_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Optimized write enable logic using direct assignment
    // Eliminates extra wire declarations and reduces logic depth
    always @* begin
        // Write operations with priority handling
        if (en_a && we_a) ram[addr_a] = din_a;
        else if (en_b && we_b) ram[addr_b] = din_b;
        
        // Read operations
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end
endmodule