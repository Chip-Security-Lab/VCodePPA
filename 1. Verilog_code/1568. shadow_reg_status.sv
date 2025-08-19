module shadow_reg_status #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid
);
    reg [DW-1:0] shadow_reg;
    always @(posedge clk) begin
        if(rst) {data_out, valid} <= 0;
        else if(en) begin
            shadow_reg <= data_in;
            valid <= 1'b0;
        end else begin
            data_out <= shadow_reg;
            valid <= 1'b1;
        end
    end
endmodule