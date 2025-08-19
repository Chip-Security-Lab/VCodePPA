module async_low_rst_fifo #(parameter DATA_WIDTH=8, DEPTH=4)(
    input wire clk,
    input wire rst_n,
    input wire wr_en, rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output wire empty, full
);
reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1];
reg [1:0] wr_ptr, rd_ptr;
reg [2:0] fifo_count;

assign empty = (fifo_count == 0);
assign full  = (fifo_count == DEPTH);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        fifo_count <= 0;
        dout <= 0;
    end else begin
        if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            fifo_count <= fifo_count + 1;
        end
        if (rd_en && !empty) begin
            dout <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            fifo_count <= fifo_count - 1;
        end
    end
end
endmodule
