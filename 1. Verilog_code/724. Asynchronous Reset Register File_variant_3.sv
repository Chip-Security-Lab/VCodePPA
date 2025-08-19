//SystemVerilog
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
    output reg  [DATA_WIDTH-1:0]  rdata
);
    // Register array
    reg [DATA_WIDTH-1:0] rf [0:DEPTH-1];
    
    // Write-enable logic
    reg [DEPTH-1:0] write_enable;
    integer i;
    
    always @(*) begin
        i = 0; // Initialization
        while (i < DEPTH) begin
            write_enable[i] = (waddr == i) && we;
            i = i + 1; // Iteration step
        end
    end
    
    // Registered read to improve timing
    always @(posedge clk) begin
        rdata <= rf[raddr];
    end
    
    // Individual register with reset logic
    // This approach can improve power and area by enabling clock gating
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : reg_gen
            always @(posedge clk or negedge arst_n) begin
                if (!arst_n) begin
                    rf[j] <= {DATA_WIDTH{1'b0}};
                end
                else if (write_enable[j]) begin
                    rf[j] <= wdata;
                end
            end
        end
    endgenerate
endmodule