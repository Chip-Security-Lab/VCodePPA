//SystemVerilog
module int_ctrl_timeout #(
    parameter TIMEOUT = 8
) (
    input  wire clk,
    input  wire int_pending,
    output reg  timeout
);

    reg [3:0] counter;
    wire timeout_comb;
    
    // Determine timeout condition combinationally
    assign timeout_comb = (counter == TIMEOUT);
    
    always @(posedge clk) begin
        if (int_pending) begin
            if (timeout_comb) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
        
        // Move register from output to after combinational logic
        timeout <= timeout_comb;
    end

endmodule