//SystemVerilog
module async_reset_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output wire [DATA_WIDTH-1:0]  rdata
);

    // Register array
    reg [DATA_WIDTH-1:0] rf [0:DEPTH-1];
    
    // Read data buffer
    reg [DATA_WIDTH-1:0] rdata_reg;
    
    // Asynchronous read path
    assign rdata = rdata_reg;

    // Register file reset logic
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            for (int idx = 0; idx < DEPTH; idx++) begin
                rf[idx] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // Register file write logic
    always @(posedge clk) begin
        if (we) begin
            rf[waddr] <= wdata;
        end
    end

    // Read data buffer update
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            rdata_reg <= rf[raddr];
        end
    end

endmodule