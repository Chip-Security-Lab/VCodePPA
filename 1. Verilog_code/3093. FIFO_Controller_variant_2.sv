//SystemVerilog
module FIFO_Controller #(
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 8,
    parameter AF_THRESH = 12,
    parameter AE_THRESH = 4
)(
    input clk, rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output full,
    output empty,
    output almost_full,
    output almost_empty
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [4:0] wr_ptr, rd_ptr;
    reg [4:0] count;

    // Manchester carry chain adder signals
    wire [4:0] wr_ptr_next, rd_ptr_next, count_next;
    wire [4:0] wr_ptr_inc, rd_ptr_inc, count_inc, count_dec;
    wire [4:0] wr_ptr_inc_carry, rd_ptr_inc_carry, count_inc_carry, count_dec_carry;

    // Generate Manchester carry chain for wr_ptr increment
    assign wr_ptr_inc[0] = wr_ptr[0] ^ 1'b1;
    assign wr_ptr_inc_carry[0] = wr_ptr[0] & 1'b1;
    genvar i;
    generate
        for (i = 1; i < 5; i = i + 1) begin : WR_PTR_CARRY
            assign wr_ptr_inc[i] = wr_ptr[i] ^ wr_ptr_inc_carry[i-1];
            assign wr_ptr_inc_carry[i] = wr_ptr[i] & wr_ptr_inc_carry[i-1];
        end
    endgenerate

    // Generate Manchester carry chain for rd_ptr increment
    assign rd_ptr_inc[0] = rd_ptr[0] ^ 1'b1;
    assign rd_ptr_inc_carry[0] = rd_ptr[0] & 1'b1;
    generate
        for (i = 1; i < 5; i = i + 1) begin : RD_PTR_CARRY
            assign rd_ptr_inc[i] = rd_ptr[i] ^ rd_ptr_inc_carry[i-1];
            assign rd_ptr_inc_carry[i] = rd_ptr[i] & rd_ptr_inc_carry[i-1];
        end
    endgenerate

    // Generate Manchester carry chain for count increment
    assign count_inc[0] = count[0] ^ 1'b1;
    assign count_inc_carry[0] = count[0] & 1'b1;
    generate
        for (i = 1; i < 5; i = i + 1) begin : COUNT_INC_CARRY
            assign count_inc[i] = count[i] ^ count_inc_carry[i-1];
            assign count_inc_carry[i] = count[i] & count_inc_carry[i-1];
        end
    endgenerate

    // Generate Manchester carry chain for count decrement
    assign count_dec[0] = count[0] ^ 1'b1;
    assign count_dec_carry[0] = ~count[0];
    generate
        for (i = 1; i < 5; i = i + 1) begin : COUNT_DEC_CARRY
            assign count_dec[i] = count[i] ^ count_dec_carry[i-1];
            assign count_dec_carry[i] = ~count[i] & count_dec_carry[i-1];
        end
    endgenerate

    // Next state logic
    assign wr_ptr_next = wr_ptr_inc;
    assign rd_ptr_next = rd_ptr_inc;
    assign count_next = (wr_en && !full && !rd_en) ? count_inc :
                       (!wr_en && rd_en && !empty) ? count_dec :
                       count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            case({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr_next;
                    count <= count_next;
                end
                2'b01: begin
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr_next;
                    count <= count_next;
                end
                2'b11: begin
                    mem[wr_ptr] <= data_in;
                    data_out <= mem[rd_ptr];
                    wr_ptr <= wr_ptr_next;
                    rd_ptr <= rd_ptr_next;
                end
            endcase
        end
    end

    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign almost_full = (count >= AF_THRESH);
    assign almost_empty = (count <= AE_THRESH);
endmodule