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
    
    // Priority-based write logic with optimized priority encoding
    reg [NUM_PRIORITY_LEVELS-1:0] priority_mask;
    reg [AWIDTH-1:0] selected_waddr;
    reg [DWIDTH-1:0] selected_wdata;
    
    // Buffer registers for high fanout signals
    reg [NUM_PRIORITY_LEVELS-1:0] priority_mask_buf;
    reg [AWIDTH-1:0] selected_waddr_buf;
    reg [DWIDTH-1:0] selected_wdata_buf;
    reg priority_valid_buf;
    
    // First stage: Priority encoding
    always @(*) begin
        priority_mask = {NUM_PRIORITY_LEVELS{1'b0}};
        selected_waddr = {AWIDTH{1'b0}};
        selected_wdata = {DWIDTH{1'b0}};
        
        for (integer j = NUM_PRIORITY_LEVELS-1; j >= 0; j = j - 1) begin
            if (we[j] && !priority_mask[j]) begin
                priority_mask[j] = 1'b1;
                selected_waddr = waddr[j];
                selected_wdata = wdata[j];
            end
        end
    end
    
    // Second stage: Buffer registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask_buf <= {NUM_PRIORITY_LEVELS{1'b0}};
            selected_waddr_buf <= {AWIDTH{1'b0}};
            selected_wdata_buf <= {DWIDTH{1'b0}};
            priority_valid_buf <= 1'b0;
        end else begin
            priority_mask_buf <= priority_mask;
            selected_waddr_buf <= selected_waddr;
            selected_wdata_buf <= selected_wdata;
            priority_valid_buf <= |priority_mask;
        end
    end
    
    // Third stage: Register write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                registers[i] <= {DWIDTH{1'b0}};
            end
        end
        else if (priority_valid_buf) begin
            registers[selected_waddr_buf] <= selected_wdata_buf;
        end
    end
endmodule