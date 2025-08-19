//SystemVerilog
module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    output reg clk_out
);
    reg [5:0] counter;
    reg [3:0] mod_counter;
    reg [3:0] divisor;
    reg [3:0] next_divisor;
    wire mod_counter_full;
    wire counter_compare;
    
    // Pre-calculate conditions to reduce critical path
    assign mod_counter_full = (mod_counter == 4'd15);
    assign counter_compare = (counter >= {2'b00, divisor});
    
    // Pre-calculate next divisor value
    always @(*) begin
        next_divisor = 4'd8;
        if (mod_counter_full)
            next_divisor = 4'd8 + (modulation & {3'b000, counter[5]});
    end
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 6'd0;
            mod_counter <= 4'd0;
            divisor <= 4'd8;
            clk_out <= 1'b0;
        end else begin
            mod_counter <= mod_counter + 4'd1;
            divisor <= next_divisor;
            
            if (counter_compare) begin
                counter <= 6'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 6'd1;
            end
        end
    end
endmodule