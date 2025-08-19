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
    
    // Calculate parity for write data (even parity: XOR of all bits should be 0)
    function bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_parity = ^data;  // XOR reduction
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
            mem[wr_addr] <= wr_data;
            parity[wr_addr] <= calc_parity(wr_data);
        end
    end
    
    // Read operation
    assign rd_data = mem[rd_addr];
    
    // Error detection (check if current parity matches stored parity)
    assign parity_error = (calc_parity(rd_data) != parity[rd_addr]);
endmodule