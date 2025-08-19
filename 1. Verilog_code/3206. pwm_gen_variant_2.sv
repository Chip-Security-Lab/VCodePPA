//SystemVerilog
module pwm_gen(
    input clk,
    input reset,
    input [7:0] duty,
    input req,
    output reg ack,
    output reg pwm_out
);
    reg [7:0] counter;
    reg req_prev;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= 8'h00;
            pwm_out <= 1'b0;
            ack <= 1'b0;
            req_prev <= 1'b0;
        end else begin
            req_prev <= req;
            counter <= counter + 1'b1;
            pwm_out <= (counter == 8'hFF) ? (duty != 8'h00) : 
                      ((counter + 1'b1) < duty) ? 1'b1 : 1'b0;
            ack <= req & ~req_prev;
        end
    end
endmodule