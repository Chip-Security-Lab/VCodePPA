//SystemVerilog
module async_fifo_ctrl #(
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input wire wr_clk, rd_clk, rst_n,
    input wire wr_en, rd_en,
    output reg full, empty,
    output reg [PTR_WIDTH:0] level
);

    // Stage 1: Pointer calculation and Gray code conversion
    reg [PTR_WIDTH:0] wr_ptr_stage1, rd_ptr_stage1;
    reg [PTR_WIDTH:0] wr_ptr_sync_stage1, rd_ptr_sync_stage1;
    wire [PTR_WIDTH:0] wr_ptr_next_stage1, rd_ptr_next_stage1;
    wire [PTR_WIDTH:0] wr_ptr_gray_stage1, rd_ptr_gray_stage1;
    wire [PTR_WIDTH:0] wr_ptr_sync_gray_stage1, rd_ptr_sync_gray_stage1;
    
    // Stage 2: Status calculation
    reg [PTR_WIDTH:0] wr_ptr_stage2, rd_ptr_stage2;
    reg [PTR_WIDTH:0] wr_ptr_sync_stage2, rd_ptr_sync_stage2;
    reg [PTR_WIDTH:0] wr_ptr_gray_stage2, rd_ptr_gray_stage2;
    reg [PTR_WIDTH:0] wr_ptr_sync_gray_stage2, rd_ptr_sync_gray_stage2;
    wire full_stage2, empty_stage2;
    wire [PTR_WIDTH:0] level_stage2;

    // Han-Carlson Adder implementation
    wire [PTR_WIDTH:0] wr_ptr_inc = {PTR_WIDTH+1{wr_en && !full}};
    wire [PTR_WIDTH:0] rd_ptr_inc = {PTR_WIDTH+1{rd_en && !empty}};
    
    // Generate and Propagate signals
    wire [PTR_WIDTH:0] wr_g, wr_p;
    wire [PTR_WIDTH:0] rd_g, rd_p;
    
    // Generate and Propagate calculation
    assign wr_g = wr_ptr_stage1 & wr_ptr_inc;
    assign wr_p = wr_ptr_stage1 ^ wr_ptr_inc;
    assign rd_g = rd_ptr_stage1 & rd_ptr_inc;
    assign rd_p = rd_ptr_stage1 ^ rd_ptr_inc;
    
    // Han-Carlson prefix computation
    wire [PTR_WIDTH:0] wr_carry, rd_carry;
    wire [PTR_WIDTH:0] wr_sum, rd_sum;
    
    // Prefix computation for write pointer
    assign wr_carry[0] = wr_g[0];
    assign wr_sum[0] = wr_p[0];
    
    genvar i;
    generate
        for (i = 1; i <= PTR_WIDTH; i = i + 1) begin : prefix_wr
            assign wr_carry[i] = wr_g[i] | (wr_p[i] & wr_carry[i-1]);
            assign wr_sum[i] = wr_p[i] ^ wr_carry[i-1];
        end
    endgenerate
    
    // Prefix computation for read pointer
    assign rd_carry[0] = rd_g[0];
    assign rd_sum[0] = rd_p[0];
    
    generate
        for (i = 1; i <= PTR_WIDTH; i = i + 1) begin : prefix_rd
            assign rd_carry[i] = rd_g[i] | (rd_p[i] & rd_carry[i-1]);
            assign rd_sum[i] = rd_p[i] ^ rd_carry[i-1];
        end
    endgenerate
    
    // Next pointer calculation
    assign wr_ptr_next_stage1 = wr_sum;
    assign rd_ptr_next_stage1 = rd_sum;

    // Gray code conversion
    assign wr_ptr_gray_stage1 = wr_ptr_stage1 ^ (wr_ptr_stage1 >> 1);
    assign rd_ptr_gray_stage1 = rd_ptr_stage1 ^ (rd_ptr_stage1 >> 1);
    assign wr_ptr_sync_gray_stage1 = wr_ptr_sync_stage1 ^ (wr_ptr_sync_stage1 >> 1);
    assign rd_ptr_sync_gray_stage1 = rd_ptr_sync_stage1 ^ (rd_ptr_sync_stage1 >> 1);
    
    // Stage 2 logic
    assign full_stage2 = (wr_ptr_gray_stage2[PTR_WIDTH:PTR_WIDTH-1] == rd_ptr_sync_gray_stage2[PTR_WIDTH:PTR_WIDTH-1]) && 
                        (wr_ptr_gray_stage2[PTR_WIDTH-2:0] == rd_ptr_sync_gray_stage2[PTR_WIDTH-2:0]);
    assign empty_stage2 = (wr_ptr_sync_gray_stage2 == rd_ptr_gray_stage2);
    assign level_stage2 = wr_ptr_sync_stage2 - rd_ptr_stage2;

    // Write clock domain pipeline
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
            rd_ptr_sync_stage1 <= 0;
            wr_ptr_stage2 <= 0;
            rd_ptr_sync_stage2 <= 0;
            wr_ptr_gray_stage2 <= 0;
            rd_ptr_sync_gray_stage2 <= 0;
            full <= 0;
        end else begin
            rd_ptr_sync_stage1 <= rd_ptr_stage1;
            wr_ptr_stage1 <= wr_ptr_next_stage1;
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_sync_stage2 <= rd_ptr_sync_stage1;
            wr_ptr_gray_stage2 <= wr_ptr_gray_stage1;
            rd_ptr_sync_gray_stage2 <= rd_ptr_sync_gray_stage1;
            full <= full_stage2;
        end
    end

    // Read clock domain pipeline
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_stage1 <= 0;
            wr_ptr_sync_stage1 <= 0;
            rd_ptr_stage2 <= 0;
            wr_ptr_sync_stage2 <= 0;
            rd_ptr_gray_stage2 <= 0;
            wr_ptr_sync_gray_stage2 <= 0;
            empty <= 1;
            level <= 0;
        end else begin
            wr_ptr_sync_stage1 <= wr_ptr_stage1;
            rd_ptr_stage1 <= rd_ptr_next_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
            wr_ptr_sync_stage2 <= wr_ptr_sync_stage1;
            rd_ptr_gray_stage2 <= rd_ptr_gray_stage1;
            wr_ptr_sync_gray_stage2 <= wr_ptr_sync_gray_stage1;
            empty <= empty_stage2;
            level <= level_stage2;
        end
    end
endmodule