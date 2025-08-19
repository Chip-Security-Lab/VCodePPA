module shadow_reg_pipeline #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow, pipe_reg;
    always @(posedge clk) begin
        if(en) shadow <= data_in;
        pipe_reg <= shadow;
        data_out <= pipe_reg;
    end
endmodule