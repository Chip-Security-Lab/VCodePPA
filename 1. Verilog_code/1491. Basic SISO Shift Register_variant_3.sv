//SystemVerilog
module siso_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, data_in,
    output wire data_out
);
    reg [WIDTH-2:0] shift_reg;
    reg data_out_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= {(WIDTH-1){1'b0}};
            data_out_reg <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[WIDTH-3:0], data_in};
            data_out_reg <= shift_reg[WIDTH-2];
        end
    end
    
    assign data_out = data_out_reg;
endmodule