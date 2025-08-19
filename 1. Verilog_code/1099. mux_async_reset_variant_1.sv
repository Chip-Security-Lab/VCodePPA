//SystemVerilog
module mux_async_reset (
    input wire clock,             // Clock signal
    input wire areset_n,          // Active-low async reset
    input wire [3:0] data_a, data_b, // Data inputs
    input wire select,            // Selection control
    output reg [3:0] out_data     // Output register
);
    always @(posedge clock or negedge areset_n) begin
        if (!areset_n)
            out_data <= 4'b0;     // Reset value
        else
            out_data <= select ? data_b : data_a;
    end
endmodule