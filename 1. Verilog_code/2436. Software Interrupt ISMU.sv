module sw_interrupt_ismu(
    input clock, reset_n,
    input [3:0] hw_int,
    input [3:0] sw_int_set,
    input [3:0] sw_int_clr,
    output reg [3:0] combined_int
);
    reg [3:0] sw_int;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            sw_int <= 4'h0;
            combined_int <= 4'h0;
        end else begin
            sw_int <= (sw_int | sw_int_set) & ~sw_int_clr;
            combined_int <= hw_int | sw_int;
        end
    end
endmodule