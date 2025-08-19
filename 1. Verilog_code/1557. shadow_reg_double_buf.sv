module shadow_reg_double_buf #(parameter WIDTH=16) (
    input clk, swap,
    input [WIDTH-1:0] update_data,
    output reg [WIDTH-1:0] active_data
);
    reg [WIDTH-1:0] buffer_reg;
    always @(posedge clk) begin
        if(swap) active_data <= buffer_reg;
        else buffer_reg <= update_data;
    end
endmodule