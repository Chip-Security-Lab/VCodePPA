//SystemVerilog
module int_ctrl_timeout #(parameter TIMEOUT=8) (
    input  wire clk, 
    input  wire int_pending,
    output reg  timeout
);

reg [3:0] counter;
reg int_pending_r;
reg timeout_next;
reg [3:0] counter_next;

always @(*) begin
    // Compute next counter value
    counter_next = counter;
    if (int_pending_r) begin
        counter_next = (counter == TIMEOUT) ? 4'd0 : counter + 4'd1;
    end
    
    // Compute next timeout value
    timeout_next = (counter == TIMEOUT);
end

always @(posedge clk) begin
    // Register input signal
    int_pending_r <= int_pending;
    
    // Update counter and timeout
    counter <= counter_next;
    timeout <= timeout_next;
end

endmodule