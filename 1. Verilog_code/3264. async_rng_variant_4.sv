//SystemVerilog
module async_rng (
    input wire clk_fast,
    input wire clk_slow,
    input wire rst_n,
    output wire [15:0] random_val
);
    reg [15:0] fast_counter_reg;
    reg [15:0] fast_counter_reg_d;
    reg [15:0] captured_value_reg;

    // Fast-running counter: synchronous increment
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            fast_counter_reg <= 16'h0;
        else
            fast_counter_reg <= fast_counter_reg + 1'b1;
    end

    // Register fast_counter for retiming (moved register before combinational logic)
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            fast_counter_reg_d <= 16'h0;
        else
            fast_counter_reg_d <= fast_counter_reg;
    end

    // Capture and combine with previous value
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            captured_value_reg <= 16'h1;
        else
            captured_value_reg <= fast_counter_reg_d ^ (captured_value_reg << 1);
    end

    assign random_val = captured_value_reg;
endmodule