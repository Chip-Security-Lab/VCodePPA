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
    integer i, j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                registers[i] <= {DWIDTH{1'b0}};
            end
        end
        else begin
            // Handle writes with priority (higher index = higher priority)
            for (j = 0; j < NUM_PRIORITY_LEVELS; j = j + 1) begin
                if (we[j]) begin
                    registers[waddr[j]] <= wdata[j];
                end
            end
        end
    end
endmodule