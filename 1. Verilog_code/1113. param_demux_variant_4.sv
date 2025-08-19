//SystemVerilog
module param_demux #(
    parameter OUTPUT_COUNT = 8,         // Number of output lines
    parameter ADDR_WIDTH = 3            // Address width (log2 of outputs)
) (
    input  wire data_input,             // Single data input
    input  wire [ADDR_WIDTH-1:0] addr,  // Address selection
    output wire [OUTPUT_COUNT-1:0] out  // Multiple outputs
);
    reg [OUTPUT_COUNT-1:0] one_hot_mask;
    integer i;

    always @(*) begin
        one_hot_mask = {OUTPUT_COUNT{1'b0}};
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin
            // Simplified: set bit if i equals addr (i.e., one-hot encoding)
            if (i[ADDR_WIDTH-1:0] == addr)
                one_hot_mask[i] = 1'b1;
        end
    end

    assign out = data_input ? one_hot_mask : {OUTPUT_COUNT{1'b0}};
endmodule