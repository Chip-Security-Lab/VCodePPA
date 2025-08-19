module shadow_reg_delayed_rst #(parameter DW=16, DELAY=3) (
    input clk, rst_in,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DELAY-1:0] rst_sr;
    always @(posedge clk) begin
        rst_sr <= {rst_sr[DELAY-2:0], rst_in};
        if(|rst_sr) data_out <= 0;
        else data_out <= data_in;
    end
endmodule