//SystemVerilog
module multibit_shifter (
    input clk, reset,
    input [1:0] data_in,
    output [1:0] data_out
);
    reg [3:0] shift_reg;
    reg [1:0] data_out_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 4'h0;
            data_out_reg <= 2'h0;
        end
        else begin
            shift_reg <= {shift_reg[1:0], data_in};
            data_out_reg <= shift_reg[3:2];
        end
    end
    
    assign data_out = data_out_reg;
endmodule