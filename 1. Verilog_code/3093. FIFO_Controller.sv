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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            case({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b01: begin
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                2'b11: begin
                    mem[wr_ptr] <= data_in;
                    data_out <= mem[rd_ptr];
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                end
            endcase
        end
    end

    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign almost_full = (count >= AF_THRESH);
    assign almost_empty = (count <= AE_THRESH);
endmodule
