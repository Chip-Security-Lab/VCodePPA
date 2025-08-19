module pipo_reg #(parameter DATA_WIDTH = 8) (
    input wire clock, reset, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clock) begin
        if (reset)
            data_out <= {DATA_WIDTH{1'b0}};
        else if (enable)
            data_out <= data_in;
    end
endmodule
