module sync_width_conv #(parameter IN_W=8, OUT_W=16, DEPTH=4) (
    input clk, rst_n,
    input [IN_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output reg [OUT_W-1:0] dout
);
localparam CNT_W = $clog2(DEPTH);
reg [IN_W-1:0] buffer[0:DEPTH-1];
reg [CNT_W:0] wr_ptr = 0, rd_ptr = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) wr_ptr <= 0;
    else if (wr_en && !full) begin
        buffer[wr_ptr[CNT_W-1:0]] <= din;
        wr_ptr <= wr_ptr + 1;
    end
end

always @(posedge clk) begin
    if (rd_en && !empty) begin
        dout <= {buffer[rd_ptr[CNT_W-1:0]+1], buffer[rd_ptr[CNT_W-1:0]]};
        rd_ptr <= rd_ptr + 2;
    end
end

assign full = (wr_ptr - rd_ptr) >= DEPTH;
assign empty = (wr_ptr == rd_ptr);
endmodule