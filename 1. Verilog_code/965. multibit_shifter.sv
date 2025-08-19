module multibit_shifter (
    input clk, reset,
    input [1:0] data_in,
    output [1:0] data_out
);
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        if (reset)
            shift_reg <= 8'h00;
        else
            shift_reg <= {data_in, shift_reg[7:2]};
    end
    
    assign data_out = shift_reg[1:0];
endmodule