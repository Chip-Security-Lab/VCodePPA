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
    
    // Pipeline registers
    reg [AWIDTH-1:0] raddr_stage1;
    reg [DWIDTH-1:0] rdata_stage1;
    reg [DWIDTH-1:0] rdata_stage2;
    
    // Write priority logic
    reg [NUM_PRIORITY_LEVELS-1:0] we_stage1;
    reg [NUM_PRIORITY_LEVELS-1:0][AWIDTH-1:0] waddr_stage1;
    reg [NUM_PRIORITY_LEVELS-1:0][DWIDTH-1:0] wdata_stage1;
    
    // Stage 1: Register inputs and read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            raddr_stage1 <= {AWIDTH{1'b0}};
            rdata_stage1 <= {DWIDTH{1'b0}};
            we_stage1 <= {NUM_PRIORITY_LEVELS{1'b0}};
            waddr_stage1 <= {NUM_PRIORITY_LEVELS*AWIDTH{1'b0}};
            wdata_stage1 <= {NUM_PRIORITY_LEVELS*DWIDTH{1'b0}};
        end else begin
            raddr_stage1 <= raddr;
            rdata_stage1 <= registers[raddr];
            we_stage1 <= we;
            waddr_stage1 <= waddr;
            wdata_stage1 <= wdata;
        end
    end
    
    // Stage 2: Write with priority and forward read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage2 <= {DWIDTH{1'b0}};
            for (int i = 0; i < REG_COUNT; i = i + 1) begin
                registers[i] <= {DWIDTH{1'b0}};
            end
        end else begin
            rdata_stage2 <= rdata_stage1;
            
            // Handle writes with priority
            for (int j = NUM_PRIORITY_LEVELS-1; j >= 0; j = j - 1) begin
                if (we_stage1[j]) begin
                    registers[waddr_stage1[j]] <= wdata_stage1[j];
                end
            end
        end
    end
    
    // Output assignment
    assign rdata = rdata_stage2;
    
endmodule