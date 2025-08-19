//SystemVerilog
module SyncFifoBridge #(
    parameter DATA_W = 32,
    parameter ADDR_W = 8,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_W-1:0] data_in,
    input wire wr_en,
    input wire rd_en,
    output wire [DATA_W-1:0] data_out,
    output wire full,
    output wire empty
);

    // Memory storage
    reg [DATA_W-1:0] fifo_mem [0:DEPTH-1];
    
    // Stage 1: Pointer and Status Calculation
    reg [ADDR_W:0] wr_ptr_stage1 = 0;
    reg [ADDR_W:0] rd_ptr_stage1 = 0;
    reg full_stage1 = 0;
    reg empty_stage1 = 1;
    reg [ADDR_W-1:0] wr_addr_stage1;
    reg [ADDR_W-1:0] rd_addr_stage1;
    reg valid_write_stage1;
    reg valid_read_stage1;
    
    // Stage 2: Memory Access
    reg [ADDR_W-1:0] wr_addr_stage2;
    reg [ADDR_W-1:0] rd_addr_stage2;
    reg valid_write_stage2;
    reg valid_read_stage2;
    reg [DATA_W-1:0] data_in_stage2;
    
    // Stage 3: Data Output
    reg [DATA_W-1:0] data_out_stage3;
    reg full_stage3;
    reg empty_stage3;
    
    // Stage 1 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= 0;
            rd_ptr_stage1 <= 0;
            full_stage1 <= 0;
            empty_stage1 <= 1;
        end else begin
            // Pointer update
            if (wr_en && !full_stage1)
                wr_ptr_stage1 <= wr_ptr_stage1 + 1'b1;
            if (rd_en && !empty_stage1)
                rd_ptr_stage1 <= rd_ptr_stage1 + 1'b1;
                
            // Status calculation
            wr_addr_stage1 <= wr_ptr_stage1[ADDR_W-1:0];
            rd_addr_stage1 <= rd_ptr_stage1[ADDR_W-1:0];
            valid_write_stage1 <= wr_en && !full_stage1;
            valid_read_stage1 <= rd_en && !empty_stage1;
            
            // Status flags
            full_stage1 <= ((wr_ptr_stage1 - rd_ptr_stage1) == DEPTH-1) && wr_en && !rd_en ||
                          (full_stage1 && !(rd_en && !wr_en));
            empty_stage1 <= ((wr_ptr_stage1 - rd_ptr_stage1) == 1) && !wr_en && rd_en ||
                           (empty_stage1 && !(wr_en && !rd_en));
        end
    end
    
    // Stage 2 Logic
    always @(posedge clk) begin
        wr_addr_stage2 <= wr_addr_stage1;
        rd_addr_stage2 <= rd_addr_stage1;
        valid_write_stage2 <= valid_write_stage1;
        valid_read_stage2 <= valid_read_stage1;
        data_in_stage2 <= data_in;
        
        if (valid_write_stage1)
            fifo_mem[wr_addr_stage1] <= data_in;
    end
    
    // Stage 3 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= {DATA_W{1'b0}};
            full_stage3 <= 0;
            empty_stage3 <= 1;
        end else begin
            if (valid_read_stage2)
                data_out_stage3 <= fifo_mem[rd_addr_stage2];
            full_stage3 <= full_stage1;
            empty_stage3 <= empty_stage1;
        end
    end
    
    // Output assignments
    assign data_out = data_out_stage3;
    assign full = full_stage3;
    assign empty = empty_stage3;
    
endmodule