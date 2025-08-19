//SystemVerilog
module param_d_latch #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output reg [WIDTH-1:0] data_out
);

    // Single stage implementation with optimized enable logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else if (enable) begin
            data_out <= data_in;
        end
    end

endmodule