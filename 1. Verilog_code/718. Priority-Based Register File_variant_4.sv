//SystemVerilog
module priority_regfile #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 4,
    parameter REG_COUNT = 2**AWIDTH,
    parameter NUM_PRIORITY_LEVELS = 3
)(
    input  wire                       clk,
    input  wire                       rst_n,
    
    // Write ports with priority
    input  wire [NUM_PRIORITY_LEVELS-1:0]           we,
    input  wire [NUM_PRIORITY_LEVELS-1:0][AWIDTH-1:0] waddr,
    input  wire [NUM_PRIORITY_LEVELS-1:0][DWIDTH-1:0] wdata,
    
    // Read port
    input  wire [AWIDTH-1:0]          raddr,
    output wire [DWIDTH-1:0]          rdata
);
    // Memory array
    reg [DWIDTH-1:0] registers [0:REG_COUNT-1];
    
    // Asynchronous read
    assign rdata = registers[raddr];
    
    // Priority-based write logic
    always @(posedge clk or negedge rst_n) begin
        integer k;
        if (!rst_n) begin
            for (k = 0; k < REG_COUNT; k = k + 1) begin
                registers[k] <= {DWIDTH{1'b0}};
            end
        end
        else if (we[2]) begin
            registers[waddr[2]] <= wdata[2];
        end
        else if (we[1]) begin
            registers[waddr[1]] <= wdata[1];
        end
        else if (we[0]) begin
            registers[waddr[0]] <= wdata[0];
        end
    end
endmodule