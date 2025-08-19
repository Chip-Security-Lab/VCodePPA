module var_shift #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    input wire load,
    output wire [W-1:0] result
);
    reg [W-1:0] shift_reg;
    
    always @(posedge clock) begin
        if (clear)
            shift_reg <= 0;
        else if (load)
            shift_reg <= data;
        else
            shift_reg <= shift_reg >> shift_amt;
    end
    
    assign result = shift_reg;
endmodule