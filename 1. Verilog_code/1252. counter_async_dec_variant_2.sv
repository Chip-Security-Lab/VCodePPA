//SystemVerilog
module counter_async_dec #(parameter WIDTH=8) (
    input clk, rst, en,
    output reg [WIDTH-1:0] count
);
    wire [WIDTH-1:0] next_count;
    wire [WIDTH:0] borrow_chain;
    
    // Initialize borrow-in
    assign borrow_chain[0] = en;
    
    // Carry-lookahead structure for borrow computation
    wire [WIDTH-1:0] generate_signals;  // Generate signals
    wire [WIDTH-1:0] propagate_signals; // Propagate signals
    
    // Calculate generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : gen_gp_signals
            assign generate_signals[i] = ~count[i];
            assign propagate_signals[i] = 1'b0; // In subtraction, propagate is 0
        end
    endgenerate
    
    // Compute borrow using carry-lookahead method
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : gen_borrow
            assign borrow_chain[i+1] = generate_signals[i] & borrow_chain[i];
        end
    endgenerate
    
    // Compute next count using XOR of current count and borrow
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : gen_next_count
            assign next_count[i] = count[i] ^ borrow_chain[i];
        end
    endgenerate
    
    // Sequential logic
    always @(posedge clk, posedge rst) begin
        if (rst) count <= {WIDTH{1'b1}};
        else if (en) count <= next_count;
    end
endmodule