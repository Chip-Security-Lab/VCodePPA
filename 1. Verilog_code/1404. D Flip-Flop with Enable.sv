module d_ff_enable (
    input wire clock,
    input wire enable,
    input wire data_in,
    output reg data_out
);
    always @(posedge clock) begin
        if (enable)
            data_out <= data_in;
    end
endmodule
