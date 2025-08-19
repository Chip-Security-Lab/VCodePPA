//SystemVerilog
`timescale 1ns / 1ps
module poly1305_mac #(parameter WIDTH = 32) (
    input wire clk, reset_n,
    input wire update, finalize,
    input wire [WIDTH-1:0] r_key, s_key, data_in,
    output reg [WIDTH-1:0] mac_out,
    output reg ready, mac_valid
);
    reg [WIDTH-1:0] accumulator, r;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam ACCUMULATE = 2'b01;
    localparam FINAL = 2'b10;
    
    // Han-Carlson adder signals for (accumulator + data_in)
    wire [WIDTH-1:0] sum_result;
    wire [WIDTH-1:0] product_result;
    wire [WIDTH-1:0] mod_result;
    wire [WIDTH-1:0] final_result;
    
    // Han-Carlson adder for addition operations
    han_carlson_adder hca_inst (
        .a(accumulator),
        .b(data_in),
        .sum(sum_result)
    );
    
    // Simplified multiplier (in real implementation, would be optimized)
    assign product_result = (sum_result * r) % (2**WIDTH - 5);
    
    // Final addition for s_key
    han_carlson_adder hca_final (
        .a(accumulator),
        .b(s_key),
        .sum(final_result)
    );
    
    // Simplified polynomial calculation with Han-Carlson adders
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= 0;
            r <= 0;
            state <= IDLE;
            ready <= 1;
            mac_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (update && ready) begin
                        r <= r_key & 32'h0FFFFFFF; // Mask off top bits as in Poly1305
                        accumulator <= 0;
                        state <= ACCUMULATE;
                        ready <= 0;
                    end
                end
                ACCUMULATE: begin
                    if (update) begin
                        // Using Han-Carlson adder result and multiply by r
                        accumulator <= product_result;
                    end else if (finalize) begin
                        state <= FINAL;
                    end else ready <= 1;
                end
                FINAL: begin
                    mac_out <= final_result % (2**WIDTH);
                    mac_valid <= 1;
                    state <= IDLE;
                    ready <= 1;
                end
            endcase
        end
    end
endmodule

// Han-Carlson parallel prefix adder module
module han_carlson_adder #(parameter WIDTH = 32) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // Pre-computation stage: generate and propagate signals
    wire [WIDTH-1:0] g_pre, p_pre;
    
    // Generate and propagate for each bit position
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pre
            assign g_pre[i] = a[i] & b[i];       // Generate
            assign p_pre[i] = a[i] ^ b[i];       // Propagate (XOR for prefix adders)
        end
    endgenerate
    
    // Han-Carlson tree stages
    // For 2-bit width, we need log2(2) = 1 stage for parallel prefix
    
    // Group propagate and generate signals
    wire [WIDTH-1:0] g_s1, p_s1;
    
    // Stage 1: Process even bits
    generate
        // For bit 0 (even position)
        assign g_s1[0] = g_pre[0];
        assign p_s1[0] = p_pre[0];
        
        // For bit 1 (odd position)
        // Combine with previous bit
        assign g_s1[1] = g_pre[1] | (p_pre[1] & g_pre[0]);
        assign p_s1[1] = p_pre[1] & p_pre[0];
    endgenerate
    
    // Post-processing stage - final sum calculation
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0; // Initial carry-in is 0
    
    generate
        // Calculate carry for each position using the prefix results
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign carry[i+1] = g_s1[i] | (p_s1[i] & carry[i]);
        end
        
        // Final sum is p_pre XOR incoming carry
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p_pre[i] ^ carry[i];
        end
    endgenerate
endmodule