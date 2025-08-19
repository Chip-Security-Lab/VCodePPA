//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module async_low_rst_fifo #(
    parameter DATA_WIDTH = 8, 
    parameter DEPTH = 4,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   wr_en, 
    input  wire                   rd_en,
    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout,
    output wire                   empty, 
    output wire                   full
);

    // Memory array
    reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
    
    // Pipeline stage registers for pointers
    reg [PTR_WIDTH-1:0] wr_ptr_stage1, wr_ptr_stage2;
    reg [PTR_WIDTH-1:0] rd_ptr_stage1, rd_ptr_stage2;
    reg [PTR_WIDTH:0]   fifo_count_stage1, fifo_count_stage2;
    
    // Pipeline control signals
    reg wr_valid_stage1, wr_valid_stage2;
    reg rd_valid_stage1, rd_valid_stage2;
    
    // Pipeline data registers
    reg [DATA_WIDTH-1:0] din_stage1;
    reg [DATA_WIDTH-1:0] dout_stage1;
    
    // Read and write request pipeline
    reg wr_req_stage1, rd_req_stage1;
    
    // Optimized status signals using direct comparisons
    assign empty = (fifo_count_stage1 == {(PTR_WIDTH+1){1'b0}});
    assign full = (fifo_count_stage1 == DEPTH);

    // Stage 1: Request handling and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_req_stage1 <= 1'b0;
            rd_req_stage1 <= 1'b0;
            din_stage1 <= {DATA_WIDTH{1'b0}};
            wr_valid_stage1 <= 1'b0;
            rd_valid_stage1 <= 1'b0;
        end 
        else begin
            // Register input requests and data
            wr_req_stage1 <= wr_en;
            rd_req_stage1 <= rd_en;
            din_stage1 <= din;
            
            // Optimized validation logic - direct evaluation
            wr_valid_stage1 <= wr_en & (fifo_count_stage1 < DEPTH);
            rd_valid_stage1 <= rd_en & (fifo_count_stage1 > 0);
        end
    end
    
    // Stage 2: Pointer and count update, memory operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_stage1 <= {PTR_WIDTH{1'b0}};
            fifo_count_stage1 <= {(PTR_WIDTH+1){1'b0}};
            wr_valid_stage2 <= 1'b0;
            rd_valid_stage2 <= 1'b0;
        end 
        else begin
            // Forward control signals to next stage
            wr_valid_stage2 <= wr_valid_stage1;
            rd_valid_stage2 <= rd_valid_stage1;
            
            // Optimized fifo_count updates with priority encoding
            if (wr_valid_stage1 & ~rd_valid_stage1)      // Write only
                fifo_count_stage1 <= fifo_count_stage1 + 1'b1;
            else if (~wr_valid_stage1 & rd_valid_stage1) // Read only
                fifo_count_stage1 <= fifo_count_stage1 - 1'b1;
            // No change for both or neither operation

            // Optimized write pointer update with range check
            if (wr_valid_stage1)
                wr_ptr_stage1 <= (wr_ptr_stage1 == DEPTH-1) ? {PTR_WIDTH{1'b0}} : wr_ptr_stage1 + 1'b1;

            // Write operation (pipelined) - performed immediately after pointer update
            if (wr_valid_stage1)
                fifo_mem[wr_ptr_stage1] <= din_stage1;

            // Optimized read pointer update with range check
            if (rd_valid_stage1)
                rd_ptr_stage1 <= (rd_ptr_stage1 == DEPTH-1) ? {PTR_WIDTH{1'b0}} : rd_ptr_stage1 + 1'b1;

            // Read operation (pipelined) - performed immediately after pointer update
            if (rd_valid_stage1)
                dout_stage1 <= fifo_mem[rd_ptr_stage1];
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DATA_WIDTH{1'b0}};
            wr_ptr_stage2 <= {PTR_WIDTH{1'b0}};
            rd_ptr_stage2 <= {PTR_WIDTH{1'b0}};
            fifo_count_stage2 <= {(PTR_WIDTH+1){1'b0}};
        end 
        else begin
            // Register outputs from previous stage
            wr_ptr_stage2 <= wr_ptr_stage1;
            rd_ptr_stage2 <= rd_ptr_stage1;
            fifo_count_stage2 <= fifo_count_stage1;
            
            // Optimized data output - only update on valid read
            if (rd_valid_stage2)
                dout <= dout_stage1;
        end
    end
endmodule