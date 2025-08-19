//SystemVerilog
module lfsr_shifter #(parameter W=8) (
    input clk,
    input rst,
    output [W-1:0] prbs
);

reg [W-1:0] prbs_reg;
wire feedback;
wire [W-2:0] prbs_next;
reg [W-1:0] prbs_buf1;
reg [W-1:0] prbs_buf2;

assign feedback = prbs_reg[7] ^ prbs_reg[5];
assign prbs_next = prbs_reg[6:0];

always @(posedge clk or posedge rst) begin
    if (rst)
        prbs_reg <= 8'hFF;
    else
        prbs_reg <= {prbs_next, feedback};
end

// First stage buffer for high fanout signal
always @(posedge clk or posedge rst) begin
    if (rst)
        prbs_buf1 <= 8'hFF;
    else
        prbs_buf1 <= prbs_reg;
end

// Second stage buffer for further load balancing
always @(posedge clk or posedge rst) begin
    if (rst)
        prbs_buf2 <= 8'hFF;
    else
        prbs_buf2 <= prbs_buf1;
end

assign prbs = prbs_buf2;

endmodule