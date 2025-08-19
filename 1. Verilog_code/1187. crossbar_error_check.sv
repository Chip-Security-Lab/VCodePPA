module crossbar_error_check #(parameter DW=8) (
    input clk, rst,
    input [7:0] parity_in,
    input [2*DW-1:0] din, // 打平的数组
    output reg [2*DW-1:0] dout, // 打平的数组
    output reg error
);
wire [7:0] calc_parity;
assign calc_parity = ^{din[0 +: DW], din[DW +: DW]};

always @(posedge clk or negedge rst) begin
    if(rst) begin
        dout <= 0;
        error <= 0;
    end else begin
        error <= (parity_in != calc_parity);
        if(parity_in != calc_parity)
            dout <= 0;
        else
            dout <= din;
    end
end
endmodule