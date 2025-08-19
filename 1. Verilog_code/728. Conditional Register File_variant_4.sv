//SystemVerilog
module conditional_regfile_pipeline #(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   reset,
    
    // Write port with condition
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [WIDTH-1:0]       wr_data,
    input  wire [WIDTH-1:0]       wr_mask,
    input  wire                   wr_condition,
    
    // Read port
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [WIDTH-1:0]       rd_data
);

    // Register array
    reg [WIDTH-1:0] memory [0:DEPTH-1];

    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] wr_addr_stage1;
    reg [WIDTH-1:0] wr_data_stage1;
    reg [WIDTH-1:0] wr_mask_stage1;
    reg wr_en_stage1;
    reg wr_condition_stage1;
    reg [ADDR_WIDTH-1:0] rd_addr_stage1;

    // Pipeline stage 2 registers
    reg [ADDR_WIDTH-1:0] wr_addr_stage2;
    reg [WIDTH-1:0] wr_data_stage2;
    reg [WIDTH-1:0] wr_mask_stage2;
    reg wr_en_stage2;
    reg wr_condition_stage2;
    reg [ADDR_WIDTH-1:0] rd_addr_stage2;

    // Pipeline stage 3 registers
    reg [WIDTH-1:0] rd_data_stage3;

    // Stage 1: Input sampling
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_addr_stage1 <= 0;
            wr_data_stage1 <= 0;
            wr_mask_stage1 <= 0;
            wr_en_stage1 <= 0;
            wr_condition_stage1 <= 0;
            rd_addr_stage1 <= 0;
        end else begin
            wr_addr_stage1 <= wr_addr;
            wr_data_stage1 <= wr_data;
            wr_mask_stage1 <= wr_mask;
            wr_en_stage1 <= wr_en;
            wr_condition_stage1 <= wr_condition;
            rd_addr_stage1 <= rd_addr;
        end
    end

    // Stage 2: Write address and data processing
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_addr_stage2 <= 0;
            wr_data_stage2 <= 0;
            wr_mask_stage2 <= 0;
            wr_en_stage2 <= 0;
            wr_condition_stage2 <= 0;
            rd_addr_stage2 <= 0;
        end else begin
            wr_addr_stage2 <= wr_addr_stage1;
            wr_data_stage2 <= wr_data_stage1;
            wr_mask_stage2 <= wr_mask_stage1;
            wr_en_stage2 <= wr_en_stage1;
            wr_condition_stage2 <= wr_condition_stage1;
            rd_addr_stage2 <= rd_addr_stage1;
        end
    end

    // Stage 3: Memory access and read data
    always @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < DEPTH; i++) begin
                memory[i] <= {WIDTH{1'b0}};
            end
            rd_data_stage3 <= {WIDTH{1'b0}};
        end else begin
            // Write operation
            if (wr_en_stage2 && wr_condition_stage2) begin
                memory[wr_addr_stage2] <= (memory[wr_addr_stage2] & ~wr_mask_stage2) | (wr_data_stage2 & wr_mask_stage2);
            end
            
            // Read operation
            rd_data_stage3 <= memory[rd_addr_stage2];
        end
    end

    // Output assignment
    assign rd_data = rd_data_stage3;

endmodule