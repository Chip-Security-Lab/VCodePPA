//SystemVerilog
module mux_async_reset (
    input wire clock,                 // Clock signal
    input wire areset_n,              // Active-low async reset
    input wire [3:0] data_a, 
    input wire [3:0] data_b,          // Data inputs
    input wire select,                // Selection control
    output reg [3:0] out_data         // Output register
);

    reg [3:0] muxed_data;

    always @(*) begin
        if (select) begin
            muxed_data = data_b;
        end else begin
            muxed_data = data_a;
        end
    end

    always @(posedge clock or negedge areset_n) begin
        if (!areset_n) begin
            out_data <= 4'b0;
        end else begin
            out_data <= muxed_data;
        end
    end

endmodule