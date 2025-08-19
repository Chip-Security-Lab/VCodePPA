//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module dma_timer #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period, threshold,
    output [WIDTH-1:0] count,
    output dma_req, period_match
);
    // Internal signals
    wire [WIDTH-1:0] counter_value;
    wire period_match_signal;
    
    // Counter module instance
    timer_counter #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .period(period),
        .count(counter_value),
        .period_match(period_match_signal)
    );
    
    // DMA request generator instance
    dma_request_gen #(
        .WIDTH(WIDTH)
    ) req_gen_inst (
        .clk(clk),
        .rst(rst),
        .count(counter_value),
        .threshold(threshold),
        .dma_req(dma_req)
    );
    
    // Connect outputs
    assign count = counter_value;
    assign period_match = period_match_signal;
    
endmodule

// Counter module - handles the counting and period matching with Han-Carlson adder
module timer_counter #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period,
    output reg [WIDTH-1:0] count,
    output reg period_match
);
    // Internal signals for Han-Carlson subtractor
    wire [WIDTH-1:0] subtractor_result;
    wire [WIDTH-1:0] inverted_count;
    wire [WIDTH:0] generate_bits, propagate_bits;
    wire [WIDTH:0] carry_chain;
    
    // Generate/Propagate logic for Han-Carlson subtractor
    assign inverted_count = ~count;
    assign generate_bits[0] = 1'b1; // Initial carry for subtraction
    assign propagate_bits[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp_bits
            assign generate_bits[i+1] = period[i] & inverted_count[i];
            assign propagate_bits[i+1] = period[i] | inverted_count[i];
        end
    endgenerate
    
    // Han-Carlson parallel prefix carry chain computation
    // Pre-processing step - compute g and p
    wire [WIDTH:0] g_pre, p_pre;
    assign g_pre = generate_bits;
    assign p_pre = propagate_bits;
    
    // Han-Carlson operates on even bits first
    wire [WIDTH:0] g_even[0:$clog2(WIDTH)];
    wire [WIDTH:0] p_even[0:$clog2(WIDTH)];
    
    // Initialize even positions
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : han_carlson_init
            if (i % 2 == 0) begin
                assign g_even[0][i] = g_pre[i];
                assign p_even[0][i] = p_pre[i];
            end
        end
    endgenerate
    
    // Han-Carlson tree stages (log2(WIDTH) stages for even bits)
    generate
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin : han_carlson_even_stages
            localparam distance = 2**i;
            
            for (genvar j = 0; j <= WIDTH; j = j + 1) begin : han_carlson_even_bits
                if ((j % 2 == 0) && (j >= distance)) begin
                    assign g_even[i][j] = g_even[i-1][j] | (p_even[i-1][j] & g_even[i-1][j-distance]);
                    assign p_even[i][j] = p_even[i-1][j] & p_even[i-1][j-distance];
                end
                else if (j % 2 == 0) begin
                    assign g_even[i][j] = g_even[i-1][j];
                    assign p_even[i][j] = p_even[i-1][j];
                end
            end
        end
    endgenerate
    
    // Compute odd positions (final step of Han-Carlson)
    wire [WIDTH:0] g_final, p_final;
    
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : han_carlson_final
            if (i % 2 == 0) begin
                // Even positions already computed
                assign g_final[i] = g_even[$clog2(WIDTH)][i];
                assign p_final[i] = p_even[$clog2(WIDTH)][i];
            end
            else begin
                // Odd positions computed from adjacent even positions
                assign g_final[i] = g_pre[i] | (p_pre[i] & g_final[i-1]);
                assign p_final[i] = p_pre[i] & p_final[i-1];
            end
        end
    endgenerate
    
    // Assign carry chain from final g values
    assign carry_chain = g_final;
    
    // Subtractor result computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor_result
            assign subtractor_result[i] = period[i] ^ inverted_count[i] ^ carry_chain[i];
        end
    endgenerate
    
    // Compare subtractor result for period matching
    wire is_one;
    assign is_one = (subtractor_result == 1'b1);
    
    always @(posedge clk) begin
        if (rst) begin 
            count <= {WIDTH{1'b0}}; 
            period_match <= 1'b0; 
        end
        else begin
            if (is_one) begin
                count <= {WIDTH{1'b0}}; 
                period_match <= 1'b1;
            end 
            else begin 
                count <= count + 1'b1; 
                period_match <= 1'b0; 
            end
        end
    end
endmodule

// DMA request generator module with Han-Carlson parallel prefix subtractor
module dma_request_gen #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] count, threshold,
    output reg dma_req
);
    // Internal signals for Han-Carlson subtractor
    wire [WIDTH-1:0] subtractor_result;
    wire [WIDTH-1:0] inverted_count;
    wire [WIDTH:0] generate_bits, propagate_bits;
    wire [WIDTH:0] carry_chain;
    
    // Generate/Propagate logic for Han-Carlson subtractor
    assign inverted_count = ~count;
    assign generate_bits[0] = 1'b1; // Initial carry for subtraction
    assign propagate_bits[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp_bits
            assign generate_bits[i+1] = threshold[i] & inverted_count[i];
            assign propagate_bits[i+1] = threshold[i] | inverted_count[i];
        end
    endgenerate
    
    // Han-Carlson parallel prefix carry chain computation
    // Pre-processing step - compute g and p
    wire [WIDTH:0] g_pre, p_pre;
    assign g_pre = generate_bits;
    assign p_pre = propagate_bits;
    
    // Han-Carlson operates on even bits first
    wire [WIDTH:0] g_even[0:$clog2(WIDTH)];
    wire [WIDTH:0] p_even[0:$clog2(WIDTH)];
    
    // Initialize even positions
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : han_carlson_init
            if (i % 2 == 0) begin
                assign g_even[0][i] = g_pre[i];
                assign p_even[0][i] = p_pre[i];
            end
        end
    endgenerate
    
    // Han-Carlson tree stages (log2(WIDTH) stages for even bits)
    generate
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin : han_carlson_even_stages
            localparam distance = 2**i;
            
            for (genvar j = 0; j <= WIDTH; j = j + 1) begin : han_carlson_even_bits
                if ((j % 2 == 0) && (j >= distance)) begin
                    assign g_even[i][j] = g_even[i-1][j] | (p_even[i-1][j] & g_even[i-1][j-distance]);
                    assign p_even[i][j] = p_even[i-1][j] & p_even[i-1][j-distance];
                end
                else if (j % 2 == 0) begin
                    assign g_even[i][j] = g_even[i-1][j];
                    assign p_even[i][j] = p_even[i-1][j];
                end
            end
        end
    endgenerate
    
    // Compute odd positions (final step of Han-Carlson)
    wire [WIDTH:0] g_final, p_final;
    
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : han_carlson_final
            if (i % 2 == 0) begin
                // Even positions already computed
                assign g_final[i] = g_even[$clog2(WIDTH)][i];
                assign p_final[i] = p_even[$clog2(WIDTH)][i];
            end
            else begin
                // Odd positions computed from adjacent even positions
                assign g_final[i] = g_pre[i] | (p_pre[i] & g_final[i-1]);
                assign p_final[i] = p_pre[i] & p_final[i-1];
            end
        end
    endgenerate
    
    // Assign carry chain from final g values
    assign carry_chain = g_final;
    
    // Subtractor result computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor_result
            assign subtractor_result[i] = threshold[i] ^ inverted_count[i] ^ carry_chain[i];
        end
    endgenerate
    
    // Compare subtractor result for threshold matching
    wire is_one;
    assign is_one = (subtractor_result == 1'b1);
    
    always @(posedge clk) begin
        if (rst) 
            dma_req <= 1'b0;
        else 
            dma_req <= is_one;
    end
endmodule