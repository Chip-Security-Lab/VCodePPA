module async_reset_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,      // Active-low asynchronous reset
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output wire [DATA_WIDTH-1:0]  rdata
);
    // Register array
    reg [DATA_WIDTH-1:0] rf [0:DEPTH-1];
    
    // Asynchronous read
    assign rdata = rf[raddr];
    
    // Synchronous write with asynchronous reset
    integer idx;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            // Reset all registers asynchronously
            for (idx = 0; idx < DEPTH; idx = idx + 1) begin
                rf[idx] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (we) begin
            rf[waddr] <= wdata;
        end
    end
endmodule