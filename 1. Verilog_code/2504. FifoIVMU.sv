module FifoIVMU #(parameter DEPTH = 4, parameter ADDR_W = 32) (
    input clk, rst,
    input [7:0] new_irq,
    input ack,
    output [ADDR_W-1:0] curr_vector,
    output has_pending
);
    reg [ADDR_W-1:0] vector_fifo [0:DEPTH-1];
    reg [ADDR_W-1:0] vector_table [0:7];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    wire empty, full;
    integer i;
    
    initial for (i = 0; i < 8; i = i + 1) 
        vector_table[i] = 32'h3000_0000 + (i << 3);
    
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) && 
                 (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]);
    assign has_pending = ~empty;
    assign curr_vector = empty ? 0 : vector_fifo[rd_ptr[$clog2(DEPTH)-1:0]];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0; rd_ptr <= 0;
        end else begin
            for (i = 0; i < 8; i = i + 1) begin
                if (new_irq[i] && !full) begin
                    vector_fifo[wr_ptr[$clog2(DEPTH)-1:0]] <= vector_table[i];
                    wr_ptr <= wr_ptr + 1;
                end
            end
            if (ack && !empty) rd_ptr <= rd_ptr + 1;
        end
    end
endmodule