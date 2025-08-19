module circ_shift_reg #(
    parameter WIDTH = 12
)(
    input clk, rstn, en, dir,
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] shifter_out
);
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            shifter_out <= {WIDTH{1'b0}};
        else if (load_en)
            shifter_out <= load_val;
        else if (en)
            shifter_out <= dir ? {shifter_out[WIDTH-2:0], shifter_out[WIDTH-1]} : 
                                 {shifter_out[0], shifter_out[WIDTH-1:1]};
    end
endmodule