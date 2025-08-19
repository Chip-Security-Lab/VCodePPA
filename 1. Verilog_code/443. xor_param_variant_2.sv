//SystemVerilog
//
// Top-level module
//
module xor_param #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] a, b,
    output [WIDTH-1:0] y
);
    // Internal signals
    wire [WIDTH-1:0] subtractor_result;
    
    // Instantiate look-ahead borrow subtractor module
    look_ahead_borrow_subtractor #(
        .BIT_WIDTH(WIDTH)
    ) subtractor_inst (
        .minuend(a),
        .subtrahend(b),
        .difference(subtractor_result)
    );
    
    // Output assignment
    assign y = subtractor_result;
    
endmodule

//
// Look-Ahead Borrow Subtractor module
//
module look_ahead_borrow_subtractor #(
    parameter BIT_WIDTH = 4
)(
    input  [BIT_WIDTH-1:0] minuend,
    input  [BIT_WIDTH-1:0] subtrahend,
    output [BIT_WIDTH-1:0] difference
);
    // Internal signals
    wire [BIT_WIDTH:0] borrow;
    wire [BIT_WIDTH-1:0] p; // Propagate signal
    wire [BIT_WIDTH-1:0] g; // Generate signal
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_pg_signals
            // Borrow generate: g[i] = ~minuend[i] & subtrahend[i]
            assign g[i] = ~minuend[i] & subtrahend[i];
            
            // Borrow propagate: p[i] = minuend[i] ^ subtrahend[i]
            assign p[i] = minuend[i] ^ subtrahend[i];
        end
    endgenerate
    
    // First stage borrow is 0
    assign borrow[0] = 1'b0;
    
    // Look-ahead borrow generation
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_borrow
            if (i == 0) begin
                assign borrow[1] = g[0] | (p[0] & borrow[0]);
            end
            else begin
                assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
            end
        end
    endgenerate
    
    // Calculate differences
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_diff
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
        end
    endgenerate
    
endmodule