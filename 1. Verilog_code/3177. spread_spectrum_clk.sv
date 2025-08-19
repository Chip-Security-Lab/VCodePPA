module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    output reg clk_out
);
    reg [5:0] counter;
    reg [3:0] mod_counter;
    reg [3:0] divisor;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 6'd0;
            mod_counter <= 4'd0;
            divisor <= 4'd8;
            clk_out <= 1'b0;
        end else begin
            mod_counter <= mod_counter + 4'd1;
            if (mod_counter == 4'd15)
                divisor <= 4'd8 + (modulation & {3'b000, counter[5]});
            if (counter >= {2'b00, divisor}) begin
                counter <= 6'd0;
                clk_out <= ~clk_out;
            end else
                counter <= counter + 6'd1;
        end
    end
endmodule