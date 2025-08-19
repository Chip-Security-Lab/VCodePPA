//SystemVerilog
module async_divider (
    input wire master_clk,
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk
);
    // Use synchronous design instead of asynchronous for better timing
    reg [2:0] counter;
    
    // Buffer registers for counter outputs to reduce fanout
    reg counter_bit0_buf1, counter_bit0_buf2;
    reg counter_bit1_buf1, counter_bit1_buf2;
    reg counter_bit2_buf1, counter_bit2_buf2;
    
    // Initialize counter to avoid X-state in simulation
    initial begin
        counter = 3'b000;
        counter_bit0_buf1 = 1'b0;
        counter_bit0_buf2 = 1'b0;
        counter_bit1_buf1 = 1'b0;
        counter_bit1_buf2 = 1'b0;
        counter_bit2_buf1 = 1'b0;
        counter_bit2_buf2 = 1'b0;
    end
    
    // Single clock domain design reduces timing issues
    always @(posedge master_clk) begin
        counter <= counter + 1'b1;
        
        // First stage buffer
        counter_bit0_buf1 <= counter[0];
        counter_bit1_buf1 <= counter[1];
        counter_bit2_buf1 <= counter[2];
        
        // Second stage buffer - distributes load further
        counter_bit0_buf2 <= counter_bit0_buf1;
        counter_bit1_buf2 <= counter_bit1_buf1;
        counter_bit2_buf2 <= counter_bit2_buf1;
    end
    
    // Generate output clocks using buffered signals
    // This reduces fanout and improves timing
    assign div2_clk = counter_bit0_buf2;
    assign div4_clk = counter_bit1_buf2;
    assign div8_clk = counter_bit2_buf2;
endmodule