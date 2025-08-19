module flagged_shift_reg #(parameter DEPTH = 8) (
    input wire clk, rst, push, pop,
    input wire data_in,
    output wire data_out,
    output wire empty, full
);
    reg [DEPTH-1:0] fifo;
    reg [$clog2(DEPTH):0] count;
    
    always @(posedge clk) begin
        if (rst) begin
            fifo <= 0;
            count <= 0;
        end else if (push && !full) begin
            fifo <= {fifo[DEPTH-2:0], data_in};
            count <= count + 1;
        end else if (pop && !empty) begin
            fifo <= {1'b0, fifo[DEPTH-1:1]};
            count <= count - 1;
        end
    end
    
    assign data_out = fifo[DEPTH-1];
    assign empty = (count == 0);
    assign full = (count == DEPTH);
endmodule