module async_rng (
    input wire clk_fast,
    input wire clk_slow,
    input wire rst_n,
    output wire [15:0] random_val
);
    reg [15:0] fast_counter;
    reg [15:0] captured_value;
    
    // Fast-running counter (asynchronous to system)
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            fast_counter <= 16'h0;
        else
            fast_counter <= fast_counter + 1'b1;
    end
    
    // Capture counter value on system clock
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            captured_value <= 16'h1;
        else
            captured_value <= fast_counter ^ (captured_value << 1);
    end
    
    assign random_val = captured_value;
endmodule