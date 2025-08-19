module AsyncFIFOShift #(parameter DEPTH=8, AW=$clog2(DEPTH)) (
    input wr_clk, rd_clk,
    input wr_en, rd_en,
    input din,
    output dout
);
reg [DEPTH-1:0] mem = 0;
reg [AW:0] wr_ptr = 0, rd_ptr = 0;

always @(posedge wr_clk) begin
    if (wr_en) begin
        mem[wr_ptr[AW-1:0]] <= din;
        wr_ptr <= wr_ptr + 1;
    end
end

always @(posedge rd_clk) begin
    if (rd_en) rd_ptr <= rd_ptr + 1;
end

assign dout = mem[rd_ptr[AW-1:0]];
endmodule
