//SystemVerilog
module switch_debouncer #(parameter DEBOUNCE_COUNT = 1000) (
    input  wire clk,
    input  wire reset,
    input  wire switch_in,
    output reg  clean_out
);
    localparam CNT_WIDTH = $clog2(DEBOUNCE_COUNT);
    reg [CNT_WIDTH-1:0] counter;
    reg switch_ff1, switch_ff2;
    
    // Double-flop synchronizer
    always @(posedge clk) begin
        switch_ff1 <= switch_in;
        switch_ff2 <= switch_ff1;
    end
    
    // Internal signals for Brent-Kung adder
    wire [CNT_WIDTH-1:0] next_counter;
    wire [CNT_WIDTH-1:0] a, b;
    wire [CNT_WIDTH-1:0] p, g;
    wire [CNT_WIDTH:0] carry;
    
    // Brent-Kung adder implementation
    assign a = counter;
    assign b = (counter == DEBOUNCE_COUNT-1) ? counter : (~8'h01 + 1'b1); // Two's complement of 1 for subtraction
    
    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & ~b;
    
    // Initial carry-in for subtraction is 1
    assign carry[0] = 1'b1;
    
    // Brent-Kung prefix computation
    // Level 1: Generate prefix pairs
    wire [CNT_WIDTH-1:0] p_l1, g_l1;
    
    genvar i;
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : prefix_level1
            if (i == 0) begin
                assign p_l1[i] = p[i];
                assign g_l1[i] = g[i] | (p[i] & carry[0]);
            end else begin
                assign p_l1[i] = p[i];
                assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            end
        end
    endgenerate
    
    // Level 2: Generate prefix pairs with stride 2
    wire [CNT_WIDTH-1:0] p_l2, g_l2;
    
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : prefix_level2
            if (i < 2) begin
                assign p_l2[i] = p_l1[i];
                assign g_l2[i] = g_l1[i];
            end else begin
                assign p_l2[i] = p_l1[i] & p_l1[i-2];
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            end
        end
    endgenerate
    
    // Level 3: Generate prefix pairs with stride 4
    wire [CNT_WIDTH-1:0] p_l3, g_l3;
    
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : prefix_level3
            if (i < 4) begin
                assign p_l3[i] = p_l2[i];
                assign g_l3[i] = g_l2[i];
            end else begin
                assign p_l3[i] = p_l2[i] & p_l2[i-4];
                assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            end
        end
    endgenerate
    
    // Backward pass - this is characteristic of Brent-Kung
    wire [CNT_WIDTH-1:0] p_b1, g_b1;
    
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : backward_level1
            if ((i % 2) == 1) begin
                assign p_b1[i] = p_l3[i];
                assign g_b1[i] = g_l3[i];
            end else if (i > 0) begin
                assign p_b1[i] = p_l3[i] & p_l1[i-1];
                assign g_b1[i] = g_l3[i] | (p_l3[i] & g_l1[i-1]);
            end else begin
                assign p_b1[i] = p_l3[i];
                assign g_b1[i] = g_l3[i];
            end
        end
    endgenerate
    
    // Compute carries from Brent-Kung network
    generate
        for (i = 0; i < CNT_WIDTH; i = i + 1) begin : carry_gen
            if ((i % 2) == 1) begin
                assign carry[i+1] = g_l3[i];
            end else if (i > 0) begin
                assign carry[i+1] = g_b1[i];
            end else begin
                assign carry[i+1] = g_b1[i];
            end
        end
    endgenerate
    
    // Sum calculation
    assign next_counter = p ^ carry[CNT_WIDTH-1:0];
    
    // Counter-based debouncer with Brent-Kung adder
    always @(posedge clk) begin
        if (reset) begin
            counter <= {CNT_WIDTH{1'b0}};
            clean_out <= 1'b0;
        end else if (switch_ff2 != clean_out) begin
            if (counter == DEBOUNCE_COUNT-1) begin
                clean_out <= switch_ff2;
                counter <= {CNT_WIDTH{1'b0}};
            end else begin
                counter <= next_counter;
            end
        end else begin
            counter <= {CNT_WIDTH{1'b0}};
        end
    end
endmodule