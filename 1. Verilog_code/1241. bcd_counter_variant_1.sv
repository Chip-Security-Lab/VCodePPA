//SystemVerilog
module bcd_counter (
    input clock, clear_n,
    output reg [3:0] bcd,
    output reg carry
);
    // Internal signals for next state computation
    wire [3:0] next_bcd;
    wire next_carry;
    
    // Buffered copies of bcd for fanout distribution
    reg [3:0] bcd_buf1, bcd_buf2, bcd_buf3;
    
    // Distributed next state logic using separate buffered signals
    assign next_bcd = (bcd_buf1 == 4'd9) ? 4'd0 : bcd_buf1 + 1'b1;
    assign next_carry = (bcd_buf2 == 4'd9) ? 1'b1 : 1'b0;
    
    // Sequential logic for main outputs
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            bcd <= 4'd0;
            carry <= 1'b0;
            // Reset all buffer registers simultaneously
            bcd_buf1 <= 4'd0;
            bcd_buf2 <= 4'd0;
            bcd_buf3 <= 4'd0;
        end else begin
            bcd <= next_bcd;
            carry <= next_carry;
            // Update buffer registers with the current bcd value
            // Distribute fanout load across multiple buffers
            bcd_buf1 <= bcd;
            bcd_buf2 <= bcd;
            bcd_buf3 <= bcd;
        end
    end
endmodule