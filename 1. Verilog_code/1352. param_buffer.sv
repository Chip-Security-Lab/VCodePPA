module param_buffer #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (load)
            data_out <= data_in;
    end
endmodule