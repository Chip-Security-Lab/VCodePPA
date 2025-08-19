module DynamicWidthShift #(parameter MAX_WIDTH=16) (
    input clk, rstn,
    input [$clog2(MAX_WIDTH)-1:0] width_sel,
    input din,
    output reg [MAX_WIDTH-1:0] q
);
reg [MAX_WIDTH-1:0] next_q;
integer i;

always @(*) begin
    next_q = q;
    next_q[0] = din;
    for (i=1; i<MAX_WIDTH; i=i+1) begin
        if (i < width_sel)
            next_q[i] = q[i-1];
        else
            next_q[i] = q[i];
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        q <= 0;
    end else begin
        q <= next_q;
    end
end
endmodule