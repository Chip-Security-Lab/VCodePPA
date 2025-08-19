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
    
    // Pipeline registers
    reg                   we_stage1;
    reg [ADDR_WIDTH-1:0]  waddr_stage1;
    reg [DATA_WIDTH-1:0]  wdata_stage1;
    reg [ADDR_WIDTH-1:0]  raddr_stage1;
    reg [DATA_WIDTH-1:0]  read_data_stage1;
    
    // Combined always block for stages 1 and 2
    integer idx;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            we_stage1 <= 1'b0;
            waddr_stage1 <= {ADDR_WIDTH{1'b0}};
            wdata_stage1 <= {DATA_WIDTH{1'b0}};
            raddr_stage1 <= {ADDR_WIDTH{1'b0}};
            read_data_stage1 <= {DATA_WIDTH{1'b0}};
            // Reset all registers asynchronously
            for (idx = 0; idx < DEPTH; idx = idx + 1) begin
                rf[idx] <= {DATA_WIDTH{1'b0}};
            end
            rdata <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Stage 1: Register inputs and perform read operation
            we_stage1 <= we;
            waddr_stage1 <= waddr;
            wdata_stage1 <= wdata;
            raddr_stage1 <= raddr;
            read_data_stage1 <= rf[raddr];

            // Stage 2: Handle write operation and output read result
            // Write operation from pipeline stage 1
            if (we_stage1) begin
                rf[waddr_stage1] <= wdata_stage1;
            end
            
            // Forward read data to output
            rdata <= read_data_stage1;
            
            // Handle read-after-write hazard
            if (we_stage1 && (raddr_stage1 == waddr_stage1)) begin
                rdata <= wdata_stage1;
            end
        end
    end
endmodule