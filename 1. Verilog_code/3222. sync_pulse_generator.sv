module sync_pulse_generator(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] period_i,
    input [15:0] width_i,
    output reg pulse_o
);
    reg [15:0] counter;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= 16'd0;
            pulse_o <= 1'b0;
        end else if (en_i) begin
            if (counter >= period_i-1)
                counter <= 16'd0;
            else
                counter <= counter + 16'd1;
                
            pulse_o <= (counter < width_i) ? 1'b1 : 1'b0;
        end
    end
endmodule