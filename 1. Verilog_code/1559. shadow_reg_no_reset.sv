module shadow_reg_no_reset #(parameter WIDTH=4) (
    input clk, enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    reg [WIDTH-1:0] shadow_store;
    always @(posedge clk) begin
        shadow_store <= enable ? input_data : shadow_store;
        output_data <= shadow_store;
    end
endmodule