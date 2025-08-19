module circular_queue #(parameter DW=8, DEPTH=16) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg full, empty
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] r_ptr, w_ptr;
    reg [4:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr <= 0; w_ptr <= 0; count <= 0;
        end else if (en) begin
            if (!full) begin
                mem[w_ptr] <= data_in;
                w_ptr <= (w_ptr + 1) % DEPTH;
                count <= count + 1;
            end
            if (!empty) begin
                data_out <= mem[r_ptr];
                r_ptr <= (r_ptr + 1) % DEPTH;
                count <= count - 1;
            end
        end
        full <= (count == DEPTH); empty <= (count == 0);
    end
endmodule
