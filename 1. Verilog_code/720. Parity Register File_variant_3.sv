//SystemVerilog
module parity_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Write interface
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    
    // Read interface
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rd_data,
    
    // Error detection
    output wire                   parity_error
);

    // Storage for data and parity
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] parity;  // One parity bit per register
    
    // Buffers for high fanout signals
    reg [DATA_WIDTH-1:0] wr_data_buf;
    reg [DEPTH-1:0] parity_buf;

    // LUT-based parity calculation
    function bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        reg [3:0] lut_parity;
        begin
            // 4-bit LUT for parity calculation
            lut_parity = {data[15:12] ^ data[11:8], data[7:4] ^ data[3:0]};
            calc_parity = ^lut_parity;
        end
    endfunction
    
    // Write operation with parity calculation
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
                parity[i] <= 1'b0;
            end
        end
        else if (wr_en) begin
            wr_data_buf <= wr_data; // Buffering write data
            mem[wr_addr] <= wr_data_buf;
            parity_buf[wr_addr] <= calc_parity(wr_data_buf); // Buffering parity calculation
        end
    end
    
    // Update parity after writing
    always @(posedge clk) begin
        if (wr_en) begin
            parity[wr_addr] <= parity_buf[wr_addr];
        end
    end
    
    // Read operation
    assign rd_data = mem[rd_addr];
    
    // Error detection (check if current parity matches stored parity)
    assign parity_error = (calc_parity(rd_data) != parity[rd_addr]);
endmodule