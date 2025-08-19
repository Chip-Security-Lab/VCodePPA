//SystemVerilog
module async_rng (
    input wire clk_fast,
    input wire clk_slow,
    input wire rst_n,
    output wire [15:0] random_val
);

    reg [15:0] fast_counter_comb;
    reg [15:0] fast_counter_reg;
    reg [15:0] captured_value_reg;

    // Move fast_counter register after adder logic (forward retiming)
    always @(*) begin : fast_counter_comb_proc
        fast_counter_comb = fast_counter_reg + 16'h1;
    end

    always @(posedge clk_fast or negedge rst_n) begin : fast_counter_reg_proc
        if (!rst_n)
            fast_counter_reg <= 16'h0;
        else
            fast_counter_reg <= fast_counter_comb;
    end

    // Captured Value Logic: Updates on clk_slow rising edge or resets on rst_n deassertion
    reg [15:0] xor_result;
    always @(*) begin : captured_value_comb_proc
        xor_result = fast_counter_reg ^ (captured_value_reg << 1);
    end

    always @(posedge clk_slow or negedge rst_n) begin : captured_value_reg_proc
        if (!rst_n)
            captured_value_reg <= 16'h1;
        else
            captured_value_reg <= xor_result;
    end

    // Output Assignment: Connects captured_value to output random_val
    assign random_val = captured_value_reg;

endmodule