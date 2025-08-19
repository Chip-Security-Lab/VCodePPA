//SystemVerilog
module priority_regfile #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 4,
    parameter REG_COUNT = 2**AWIDTH,
    parameter NUM_PRIORITY_LEVELS = 3
)(
    input  wire                       clk,
    input  wire                       rst_n,
    
    input  wire [NUM_PRIORITY_LEVELS-1:0]           we,
    input  wire [NUM_PRIORITY_LEVELS-1:0][AWIDTH-1:0] waddr,
    input  wire [NUM_PRIORITY_LEVELS-1:0][DWIDTH-1:0] wdata,
    
    input  wire [AWIDTH-1:0]          raddr,
    output wire [DWIDTH-1:0]          rdata
);

    reg [DWIDTH-1:0] registers [0:REG_COUNT-1];
    
    // Pipeline registers
    reg [AWIDTH-1:0] raddr_stage1;
    reg [AWIDTH-1:0] raddr_stage2;
    reg [AWIDTH-1:0] raddr_stage3;
    reg [DWIDTH-1:0] rdata_stage1;
    reg [DWIDTH-1:0] rdata_stage2;
    reg [DWIDTH-1:0] rdata_stage3;
    
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    reg [NUM_PRIORITY_LEVELS-1:0] we_stage1;
    reg [NUM_PRIORITY_LEVELS-1:0] we_stage2;
    reg [NUM_PRIORITY_LEVELS-1:0][AWIDTH-1:0] waddr_stage1;
    reg [NUM_PRIORITY_LEVELS-1:0][AWIDTH-1:0] waddr_stage2;
    reg [NUM_PRIORITY_LEVELS-1:0][DWIDTH-1:0] wdata_stage1;
    reg [NUM_PRIORITY_LEVELS-1:0][DWIDTH-1:0] wdata_stage2;
    
    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            we_stage1 <= {NUM_PRIORITY_LEVELS{1'b0}};
            waddr_stage1 <= {NUM_PRIORITY_LEVELS{{AWIDTH{1'b0}}}};
            wdata_stage1 <= {NUM_PRIORITY_LEVELS{{DWIDTH{1'b0}}}};
            raddr_stage1 <= {AWIDTH{1'b0}};
        end else begin
            valid_stage1 <= 1'b1;
            we_stage1 <= we;
            waddr_stage1 <= waddr;
            wdata_stage1 <= wdata;
            raddr_stage1 <= raddr;
        end
    end
    
    // Stage 2: Priority write preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            we_stage2 <= {NUM_PRIORITY_LEVELS{1'b0}};
            waddr_stage2 <= {NUM_PRIORITY_LEVELS{{AWIDTH{1'b0}}}};
            wdata_stage2 <= {NUM_PRIORITY_LEVELS{{DWIDTH{1'b0}}}};
            raddr_stage2 <= {AWIDTH{1'b0}};
        end else begin
            valid_stage2 <= valid_stage1;
            we_stage2 <= we_stage1;
            waddr_stage2 <= waddr_stage1;
            wdata_stage2 <= wdata_stage1;
            raddr_stage2 <= raddr_stage1;
        end
    end
    
    // Stage 3: Memory access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            raddr_stage3 <= {AWIDTH{1'b0}};
            rdata_stage1 <= {DWIDTH{1'b0}};
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                registers[i] <= {DWIDTH{1'b0}};
            end
        end else begin
            valid_stage3 <= valid_stage2;
            raddr_stage3 <= raddr_stage2;
            rdata_stage1 <= registers[raddr_stage2];
            
            for (integer j = 0; j < NUM_PRIORITY_LEVELS; j = j + 1) begin
                if (we_stage2[j]) begin
                    registers[waddr_stage2[j]] <= wdata_stage2[j];
                end
            end
        end
    end
    
    // Stage 4: Read data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage2 <= {DWIDTH{1'b0}};
        end else begin
            rdata_stage2 <= rdata_stage1;
        end
    end
    
    // Stage 5: Final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage3 <= {DWIDTH{1'b0}};
        end else begin
            rdata_stage3 <= rdata_stage2;
        end
    end
    
    assign rdata = rdata_stage3;
    
endmodule