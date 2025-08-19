//SystemVerilog
module shadow_reg_no_reset #(parameter WIDTH=4) (
    input clk,
    input enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);

    // Direct update of output data with synchronized shadow storage
    always @(posedge clk) begin
        // Output is updated with shadow data on every clock cycle
        output_data <= enable ? input_data : output_data;
    end
endmodule