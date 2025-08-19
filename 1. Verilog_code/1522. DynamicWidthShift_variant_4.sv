//SystemVerilog
// IEEE 1364-2005 Verilog standard
module DynamicWidthShift #(parameter MAX_WIDTH=16) (
    input clk, rstn,
    input [$clog2(MAX_WIDTH)-1:0] width_sel,
    input din,
    output reg [MAX_WIDTH-1:0] q
);
    // Intermediate buffers for high fanout signals
    reg [MAX_WIDTH-1:0] next_q;
    reg [MAX_WIDTH-1:0] q_buf;
    reg [$clog2(MAX_WIDTH)-1:0] width_sel_buf;
    integer i;

    // Combinational logic for next state calculation
    always @(*) begin
        next_q = q_buf;
        next_q[0] = din;
        for (i=1; i<MAX_WIDTH; i=i+1) begin
            if (i < width_sel_buf)
                next_q[i] = q_buf[i-1];
        end
    end

    // Merged sequential logic with same clock edge trigger
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            width_sel_buf <= 0;
            q_buf <= 0;
            q <= 0;
        end else begin
            width_sel_buf <= width_sel;
            q_buf <= next_q;
            q <= q_buf;
        end
    end
endmodule