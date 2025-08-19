//SystemVerilog
module SyncFIFOCompress #(
    parameter DW = 8,   // Data width
    parameter AW = 12   // Address width
) (
    input                  clk,
    input                  rst_n,
    input                  wr_en,
    input                  rd_en,
    input      [DW-1:0]    din,
    output reg [DW-1:0]    dout,
    output                 full,
    output                 empty
);
    // Memory array
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Increased pipeline stage registers for pointers
    reg [AW:0] wr_ptr_stage1 = 0;
    reg [AW:0] rd_ptr_stage1 = 0;
    reg [AW:0] wr_ptr_stage2 = 0;
    reg [AW:0] rd_ptr_stage2 = 0;
    reg [AW:0] wr_ptr_stage3 = 0;
    reg [AW:0] rd_ptr_stage3 = 0;
    reg [AW:0] wr_ptr_stage4 = 0;
    reg [AW:0] rd_ptr_stage4 = 0;
    
    // Extended pipeline control signals
    reg wr_valid_stage1 = 0, rd_valid_stage1 = 0;
    reg wr_valid_stage2 = 0, rd_valid_stage2 = 0;
    reg wr_valid_stage3 = 0, rd_valid_stage3 = 0;
    reg wr_valid_stage4 = 0, rd_valid_stage4 = 0;
    
    // Data pipeline registers
    reg [DW-1:0] din_stage1 = 0;
    reg [DW-1:0] din_stage2 = 0;
    reg [DW-1:0] din_stage3 = 0;
    
    // Address calculation pipeline registers
    reg [AW-1:0] wr_addr_stage2 = 0;
    reg [AW-1:0] rd_addr_stage2 = 0;
    reg [AW-1:0] wr_addr_stage3 = 0;
    reg [AW-1:0] rd_addr_stage3 = 0;
    
    // Pointer difference calculation pipeline
    wire [AW:0] inverted_rd_ptr_stage1;
    reg [AW:0] inverted_rd_ptr_stage2 = 0;
    
    wire [AW:0] adder_result_stage1;
    reg [AW:0] adder_result_stage2 = 0;
    reg [AW:0] adder_result_stage3 = 0;
    
    wire borrow_stage1;
    reg borrow_stage2 = 0;
    reg borrow_stage3 = 0;
    
    reg [AW:0] ptr_diff_stage3 = 0;
    reg [AW:0] ptr_diff_stage4 = 0;
    
    // Stage 1: Input registration 
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_valid_stage1 <= 0;
            rd_valid_stage1 <= 0;
            din_stage1 <= 0;
            wr_ptr_stage1 <= 0;
            rd_ptr_stage1 <= 0;
        end else begin
            wr_valid_stage1 <= wr_en;
            rd_valid_stage1 <= rd_en;
            din_stage1 <= din;
            
            // The pointers are updated in stage 1 but depend on full/empty signals
            // which are calculated based on stage 4 values
            if (wr_en && !full) 
                wr_ptr_stage1 <= wr_ptr_stage4 + 1'b1;
            else
                wr_ptr_stage1 <= wr_ptr_stage4;
                
            if (rd_en && !empty)
                rd_ptr_stage1 <= rd_ptr_stage4 + 1'b1;
            else
                rd_ptr_stage1 <= rd_ptr_stage4;
        end
    end
    
    // Calculate pointer difference - split between stages
    assign inverted_rd_ptr_stage1 = ~rd_ptr_stage1;
    assign {borrow_stage1, adder_result_stage1} = wr_ptr_stage1 + inverted_rd_ptr_stage1 + 1'b1;
    
    // Stage 2: Address extraction and continuation of difference calculation
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= 0;
            rd_ptr_stage2 <= 0;
            wr_valid_stage2 <= 0;
            rd_valid_stage2 <= 0;
            din_stage2 <= 0;
            wr_addr_stage2 <= 0;
            rd_addr_stage2 <= 0;
            inverted_rd_ptr_stage2 <= 0;
            adder_result_stage2 <= 0;
            borrow_stage2 <= 0;
        end else begin
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
            wr_valid_stage2 <= wr_valid_stage1;
            rd_valid_stage2 <= rd_valid_stage1;
            din_stage2 <= din_stage1;
            
            // Extract addresses for memory operations
            wr_addr_stage2 <= wr_ptr_stage1[AW-1:0];
            rd_addr_stage2 <= rd_ptr_stage1[AW-1:0];
            
            // Continue pointer difference calculation
            inverted_rd_ptr_stage2 <= inverted_rd_ptr_stage1;
            adder_result_stage2 <= adder_result_stage1;
            borrow_stage2 <= borrow_stage1;
        end
    end
    
    // Stage 3: Memory operation preparation and pointer difference finalization
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage3 <= 0;
            rd_ptr_stage3 <= 0;
            wr_valid_stage3 <= 0;
            rd_valid_stage3 <= 0;
            din_stage3 <= 0;
            wr_addr_stage3 <= 0;
            rd_addr_stage3 <= 0;
            adder_result_stage3 <= 0;
            borrow_stage3 <= 0;
            ptr_diff_stage3 <= 0;
        end else begin
            wr_ptr_stage3 <= wr_ptr_stage2;
            rd_ptr_stage3 <= rd_ptr_stage2;
            wr_valid_stage3 <= wr_valid_stage2;
            rd_valid_stage3 <= rd_valid_stage2;
            din_stage3 <= din_stage2;
            wr_addr_stage3 <= wr_addr_stage2;
            rd_addr_stage3 <= rd_addr_stage2;
            
            // Finalize pointer difference calculation
            adder_result_stage3 <= adder_result_stage2;
            borrow_stage3 <= borrow_stage2;
            ptr_diff_stage3 <= adder_result_stage2; // Store the difference
        end
    end
    
    // Stage 4: Actual memory operations and status flags
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_stage4 <= 0;
            rd_ptr_stage4 <= 0;
            wr_valid_stage4 <= 0;
            rd_valid_stage4 <= 0;
            ptr_diff_stage4 <= 0;
        end else begin
            wr_ptr_stage4 <= wr_ptr_stage3;
            rd_ptr_stage4 <= rd_ptr_stage3;
            wr_valid_stage4 <= wr_valid_stage3;
            rd_valid_stage4 <= rd_valid_stage3;
            ptr_diff_stage4 <= ptr_diff_stage3;
            
            // Memory write operation in stage 4
            if (wr_valid_stage3 && !full) begin
                mem[wr_addr_stage3] <= din_stage3;
            end
            
            // Memory read operation in stage 4
            if (rd_valid_stage3 && !empty) begin
                dout <= mem[rd_addr_stage3];
            end
        end
    end
    
    // Full and empty flags based on stage 4 pointer difference
    assign full = (ptr_diff_stage4 == (1<<AW));
    assign empty = (ptr_diff_stage4 == 0);
    
endmodule