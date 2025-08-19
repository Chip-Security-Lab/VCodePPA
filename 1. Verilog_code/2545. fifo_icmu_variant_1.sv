//SystemVerilog
module fifo_icmu #(
    parameter INT_COUNT = 16,
    parameter FIFO_DEPTH = 8,
    parameter CTX_WIDTH = 64
)(
    input wire clk, rstn,
    input wire [INT_COUNT-1:0] int_sources,
    input wire [CTX_WIDTH-1:0] current_ctx,
    input wire service_done,
    output reg [3:0] int_id,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg interrupt_valid,
    output reg fifo_full, fifo_empty
);
    reg [3:0] id_fifo [FIFO_DEPTH-1:0];
    reg [CTX_WIDTH-1:0] ctx_fifo [FIFO_DEPTH-1:0];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(FIFO_DEPTH):0] count;
    reg [INT_COUNT-1:0] last_sources;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_ptr <= 0; rd_ptr <= 0; count <= 0;
            last_sources <= 0; interrupt_valid <= 0;
            fifo_empty <= 1; fifo_full <= 0;
        end else begin
            // Detect new interrupts
            for (integer i = 0; i < INT_COUNT; i = i+1) begin
                if (int_sources[i] & ~last_sources[i] & ~fifo_full) begin
                    id_fifo[wr_ptr] <= i[3:0];
                    ctx_fifo[wr_ptr] <= current_ctx;
                    wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
                    count <= count + 1;
                end
            end
            
            // Service completion
            if (service_done & ~fifo_empty) begin
                rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
                count <= count - 1;
            end
            
            // Update outputs
            last_sources <= int_sources;
            fifo_empty <= (count == 0);
            fifo_full <= (count == FIFO_DEPTH);
            
            // Present interrupt
            if (!fifo_empty & (!interrupt_valid | service_done)) begin
                int_id <= id_fifo[rd_ptr];
                saved_ctx <= ctx_fifo[rd_ptr];
                interrupt_valid <= 1;
            end else if (service_done) begin
                interrupt_valid <= 0;
            end
        end
    end
endmodule