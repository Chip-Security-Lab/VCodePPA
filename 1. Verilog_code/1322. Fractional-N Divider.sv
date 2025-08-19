module fractional_n_div #(
    parameter INT_DIV = 4,
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input clk_src, reset_n,
    output reg clk_out
);
    reg [3:0] int_counter;
    reg [FRAC_BITS-1:0] frac_acc;
    wire frac_overflow;
    
    assign frac_overflow = frac_acc + FRAC_DIV >= (1 << FRAC_BITS);
    
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_counter <= 0;
            frac_acc <= 0;
            clk_out <= 0;
        end else begin
            if (int_counter == (frac_overflow ? INT_DIV : INT_DIV-1) - 1) begin
                int_counter <= 0;
                frac_acc <= frac_acc + FRAC_DIV - (frac_overflow ? (1 << FRAC_BITS) : 0);
                clk_out <= ~clk_out;
            end else
                int_counter <= int_counter + 1;
        end
    end
endmodule