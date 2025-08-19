module eth_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter LOG2_DEPTH = 4
) (
    input wire i_clk,
    input wire i_rst,
    input wire i_wr_en,
    input wire i_rd_en,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data,
    output wire o_full,
    output wire o_empty
);
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    reg [LOG2_DEPTH-1:0] rd_ptr;
    reg [LOG2_DEPTH-1:0] wr_ptr;
    reg [LOG2_DEPTH:0] count;
    
    assign o_full = (count == DEPTH);
    assign o_empty = (count == 0);
    
    always @(posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (i_wr_en && !o_full) begin
                memory[wr_ptr] <= i_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                count <= count + 1;
            end
            
            if (i_rd_en && !o_empty) begin
                o_data <= memory[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                count <= count - 1;
            end
        end
    end
endmodule