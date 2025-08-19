//SystemVerilog
module dynamic_ring_buf #(parameter MAX_DEPTH=16, DW=8) (
    input clk, rst_n,
    input [3:0] depth_set,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty,
    // Pipeline control signals
    input pipe_ready,
    output pipe_valid
);
    // Memory and pointer registers
    reg [DW-1:0] mem[MAX_DEPTH-1:0];
    reg [3:0] wr_ptr, rd_ptr, cnt;
    
    // Pipeline stage registers
    // Stage 1: Command decode and depth check
    reg [3:0] depth_stage1, depth_stage2;
    reg [3:0] cnt_stage1, cnt_stage2;
    reg wr_en_stage1, rd_en_stage1;
    reg [DW-1:0] din_stage1;
    reg [3:0] wr_ptr_stage1, rd_ptr_stage1;
    reg valid_stage1;
    
    // Stage 2: Memory operation and pointer update
    reg wr_only_stage2, rd_only_stage2, wr_rd_stage2;
    reg [DW-1:0] din_stage2;
    reg [3:0] next_wr_ptr_stage2, next_rd_ptr_stage2;
    reg [DW-1:0] mem_rd_data_stage2;
    reg valid_stage2;
    
    // Stage 3: Result generation
    reg [3:0] cnt_stage3;
    reg [3:0] depth_stage3;
    reg valid_stage3;
    
    // Depth calculation logic
    wire [3:0] depth_wire = (depth_set > 4'd0 && depth_set < MAX_DEPTH) ? 
                            depth_set : 
                            (depth_set >= MAX_DEPTH) ? MAX_DEPTH : 4'd1;
    
    // ===== PIPELINE STAGE 1: Command decode and parameter preparation =====
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            depth_stage1 <= 4'd1;
            cnt_stage1 <= 4'd0;
            wr_en_stage1 <= 1'b0;
            rd_en_stage1 <= 1'b0;
            din_stage1 <= {DW{1'b0}};
            wr_ptr_stage1 <= 4'd0;
            rd_ptr_stage1 <= 4'd0;
            valid_stage1 <= 1'b0;
        end else if (pipe_ready) begin
            depth_stage1 <= depth_wire;
            cnt_stage1 <= cnt;
            wr_en_stage1 <= wr_en;
            rd_en_stage1 <= rd_en;
            din_stage1 <= din;
            wr_ptr_stage1 <= wr_ptr;
            rd_ptr_stage1 <= rd_ptr;
            valid_stage1 <= 1'b1;
        end
    end
    
    // ===== PIPELINE STAGE 2: Memory operation and pointer calculation =====
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            depth_stage2 <= 4'd1;
            cnt_stage2 <= 4'd0;
            wr_only_stage2 <= 1'b0;
            rd_only_stage2 <= 1'b0;
            wr_rd_stage2 <= 1'b0;
            din_stage2 <= {DW{1'b0}};
            next_wr_ptr_stage2 <= 4'd0;
            next_rd_ptr_stage2 <= 4'd0;
            mem_rd_data_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (pipe_ready) begin
            depth_stage2 <= depth_stage1;
            cnt_stage2 <= cnt_stage1;
            
            // Combined operation detection (moved to pipeline stage)
            wr_only_stage2 <= wr_en_stage1 && !rd_en_stage1 && (cnt_stage1 < depth_stage1);
            rd_only_stage2 <= rd_en_stage1 && !wr_en_stage1 && (cnt_stage1 > 4'd0);
            wr_rd_stage2 <= wr_en_stage1 && rd_en_stage1;
            
            din_stage2 <= din_stage1;
            
            // Pre-calculate next pointers
            next_wr_ptr_stage2 <= (wr_ptr_stage1 == depth_stage1 - 1) ? 4'd0 : wr_ptr_stage1 + 4'd1;
            next_rd_ptr_stage2 <= (rd_ptr_stage1 == depth_stage1 - 1) ? 4'd0 : rd_ptr_stage1 + 4'd1;
            
            // Pre-read memory data
            mem_rd_data_stage2 <= mem[rd_ptr_stage1];
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // ===== PIPELINE STAGE 3: Result generation and update =====
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt_stage3 <= 4'd0;
            depth_stage3 <= 4'd1;
            valid_stage3 <= 1'b0;
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            cnt <= 4'd0;
            dout <= {DW{1'b0}};
        end else if (pipe_ready) begin
            cnt_stage3 <= cnt_stage2;
            depth_stage3 <= depth_stage2;
            valid_stage3 <= valid_stage2;
            
            // Actual memory and pointer updates based on stage2 decisions
            if(wr_only_stage2) begin
                mem[wr_ptr_stage1] <= din_stage2;
                wr_ptr <= next_wr_ptr_stage2;
                cnt <= cnt_stage2 + 4'd1;
            end else if(rd_only_stage2) begin
                dout <= mem_rd_data_stage2;
                rd_ptr <= next_rd_ptr_stage2;
                cnt <= cnt_stage2 - 4'd1;
            end else if(wr_rd_stage2) begin
                mem[wr_ptr_stage1] <= din_stage2;
                wr_ptr <= next_wr_ptr_stage2;
                dout <= mem_rd_data_stage2;
                rd_ptr <= next_rd_ptr_stage2;
            end
        end
    end
    
    // Fast comparator for full and empty conditions
    wire cnt_is_zero = ~|cnt_stage3;
    
    // Optimized status flags using direct equality comparison
    assign full = cnt_stage3 == depth_stage3;
    assign empty = cnt_is_zero;
    
    // Pipeline valid signal indicates when result is ready
    assign pipe_valid = valid_stage3;
endmodule