//SystemVerilog
// Memory array submodule with improved timing
module memory_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire clk
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;  // Synchronous write
        end
        dout <= ram[addr];     // Synchronous read
    end

endmodule

// Address decoder submodule
module addr_decoder #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [2**ADDR_WIDTH-1:0] decode_out
);

    always @* begin
        decode_out = (1 << addr);
    end

endmodule

// Output control submodule with improved timing
module output_control #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire oe,
    input wire clk
);

    always @(posedge clk) begin
        if (oe) 
            data_out <= data_in;   // Synchronous output enable
        else
            data_out <= {DATA_WIDTH{1'bz}};
    end

endmodule

// Top-level module with improved architecture
module async_single_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire oe,
    input wire clk
);

    wire [DATA_WIDTH-1:0] mem_data;
    wire [2**ADDR_WIDTH-1:0] decoded_addr;
    
    // Instantiate address decoder
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_dec_inst (
        .addr(addr),
        .decode_out(decoded_addr)
    );
    
    // Instantiate memory array
    memory_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_inst (
        .addr(addr),
        .din(din),
        .dout(mem_data),
        .we(we),
        .clk(clk)
    );
    
    // Instantiate output control
    output_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_ctrl_inst (
        .data_in(mem_data),
        .data_out(dout),
        .oe(oe),
        .clk(clk)
    );

endmodule