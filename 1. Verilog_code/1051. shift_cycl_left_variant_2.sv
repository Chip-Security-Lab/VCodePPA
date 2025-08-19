//SystemVerilog
module shift_cycl_left (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 8'b0;
    end else if (en) begin
        data_out <= {data_in[6:0], data_in[7]};
    end
end
endmodule