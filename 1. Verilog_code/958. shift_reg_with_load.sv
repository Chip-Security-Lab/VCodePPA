module shift_reg_with_load (
    input wire clk, reset,
    input wire shift_en, load_en,
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        if (reset)
            shift_reg <= 8'h00;
        else if (load_en)
            shift_reg <= parallel_in;
        else if (shift_en)
            shift_reg <= {shift_reg[6:0], serial_in};
    end
    
    assign serial_out = shift_reg[7];
    assign parallel_out = shift_reg;
endmodule