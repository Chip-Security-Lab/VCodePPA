//SystemVerilog
module odd_div_biedge #(parameter N=5) (
    input  wire clk,    // System clock
    input  wire rst_n,  // Active-low reset
    output wire clk_out // Divided clock output
);
    // Clock division signals from positive and negative edge counters
    wire pos_div_out, neg_div_out;
    
    // Pipeline register for edge outputs synchronization
    reg pos_div_sync, neg_div_sync;
    
    // Instantiate positive edge counter
    edge_counter #(
        .N(N),
        .EDGE_TYPE("POSITIVE")
    ) pos_counter (
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(pos_div_out)
    );
    
    // Instantiate negative edge counter
    edge_counter #(
        .N(N),
        .EDGE_TYPE("NEGATIVE")
    ) neg_counter (
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(neg_div_out)
    );
    
    // Synchronize edge counter outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos_div_sync <= 1'b0;
            neg_div_sync <= 1'b0;
        end else begin
            pos_div_sync <= pos_div_out;
            neg_div_sync <= neg_div_out;
        end
    end
    
    // Output generation with synchronized signals
    assign clk_out = pos_div_sync ^ neg_div_sync;
endmodule

module edge_counter #(
    parameter N = 5,
    parameter EDGE_TYPE = "POSITIVE" // "POSITIVE" or "NEGATIVE"
)(
    input  wire clk,     // System clock
    input  wire rst_n,   // Active-low reset
    output reg  clk_out  // Divided clock output
);
    // Counter registers and control signals
    reg  [2:0] cnt_value;    // Current counter value
    wire [2:0] cnt_next;     // Next counter value
    wire       cnt_terminal; // Terminal count indicator
    
    // Terminal count detection
    assign cnt_terminal = (cnt_value == N-1);
    
    // Optimized adder for counter increment
    carry_lookahead_adder_3bit adder (
        .a(cnt_value),
        .b(3'b001),
        .sum(cnt_next)
    );
    
    // Edge-specific counter logic
    generate
        if (EDGE_TYPE == "POSITIVE") begin: pos_edge_logic
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt_value <= 3'b000;
                    clk_out   <= 1'b0;
                end else begin
                    if (cnt_terminal) begin
                        cnt_value <= 3'b000;
                        clk_out   <= ~clk_out;
                    end else begin
                        cnt_value <= cnt_next;
                    end
                end
            end
        end else begin: neg_edge_logic
            always @(negedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt_value <= 3'b000;
                    clk_out   <= 1'b0;
                end else begin
                    if (cnt_terminal) begin
                        cnt_value <= 3'b000;
                        clk_out   <= ~clk_out;
                    end else begin
                        cnt_value <= cnt_next;
                    end
                end
            end
        end
    endgenerate
endmodule

module carry_lookahead_adder_3bit (
    input  wire [2:0] a,   // First operand
    input  wire [2:0] b,   // Second operand
    output wire [2:0] sum  // Sum result
);
    // Internal signals for carry computation
    wire [2:0] gen;    // Generate signals
    wire [2:0] prop;   // Propagate signals
    wire [2:0] carry;  // Carry signals
    
    // Stage 1: Generate and propagate computation - parallelized
    assign gen  = a & b;       // Generate = a AND b
    assign prop = a ^ b;       // Propagate = a XOR b
    
    // Stage 2: Carry computation - optimized for timing
    // Use register-like structure for better pipelining
    assign carry[0] = 1'b0;    // No initial carry
    assign carry[1] = gen[0];  // c1 = g0
    assign carry[2] = gen[1] | (prop[1] & gen[0]); // c2 = g1 + (p1 & g0)
    
    // Stage 3: Sum computation - parallelized
    assign sum = prop ^ carry; // Sum = propagate XOR carry
endmodule