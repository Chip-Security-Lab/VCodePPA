module dynamic_ring_buf #(parameter MAX_DEPTH=16, DW=8) (
    input clk, rst_n,
    input [3:0] depth_set,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty
);
    reg [DW-1:0] mem[MAX_DEPTH-1:0];
    reg [3:0] wr_ptr=0, rd_ptr=0, cnt=0;
    wire [3:0] depth = (depth_set < MAX_DEPTH) ? depth_set : MAX_DEPTH;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) {wr_ptr, rd_ptr, cnt} <= 0;
        else begin
            case({wr_en, rd_en})
                2'b10: if(cnt < depth) begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr + 1) % depth;
                    cnt <= cnt + 1;
                end
                2'b01: if(cnt > 0) begin
                    dout <= mem[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % depth;
                    cnt <= cnt - 1;
                end
                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr + 1) % depth;
                    dout <= mem[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % depth;
                end
            endcase
        end
    end
    assign full = (cnt == depth);
    assign empty = (cnt == 0);
endmodule
