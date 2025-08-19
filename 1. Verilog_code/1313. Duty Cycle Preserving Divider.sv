module duty_preserve_divider (
    input wire clock_in, 
    input wire n_reset, 
    input wire [3:0] div_ratio,
    output reg clock_out
);
    reg [3:0] counter;
    
    always @(posedge clock_in or negedge n_reset) begin
        if (!n_reset) begin
            counter <= 4'd0;
            clock_out <= 1'b0;
        end else begin
            if (counter >= div_ratio - 1) begin
                counter <= 4'd0;
                clock_out <= ~clock_out; // Toggle output for 50% duty cycle
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule