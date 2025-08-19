//SystemVerilog
// Hierarchical 3-input AND gate with pipelined structure

// Top-level module
module and_gate_3 (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active-low reset
    input  wire a,      // Input signal A
    input  wire b,      // Input signal B
    input  wire c,      // Input signal C
    output wire y       // Output result
);

    // Internal pipeline signals
    wire [1:0] stage1_out;   // Output from first stage
    wire       stage2_out;   // Output from second stage

    // First pipeline stage: register inputs
    input_register stage1 (
        .clk     (clk),
        .rst_n   (rst_n),
        .in_a    (a),
        .in_b    (b),
        .out_a   (stage1_out[0]),
        .out_b   (stage1_out[1])
    );
    
    // Second pipeline stage: partial AND computation
    partial_and stage2 (
        .clk     (clk),
        .rst_n   (rst_n),
        .in_a    (stage1_out[0]),
        .in_b    (stage1_out[1]),
        .out     (stage2_out)
    );
    
    // Final pipeline stage: final AND computation
    final_and stage3 (
        .clk     (clk),
        .rst_n   (rst_n),
        .in_ab   (stage2_out),
        .in_c    (c),
        .out     (y)
    );

endmodule

// First stage module: Input registration
module input_register (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  out_a,
    output reg  out_b
);
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_a <= 1'b0;
            out_b <= 1'b0;
        end else begin
            out_a <= in_a;
            out_b <= in_b;
        end
    end

endmodule

// Second stage module: Partial AND computation
module partial_and (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 1'b0;
        end else begin
            out <= in_a & in_b;
        end
    end

endmodule

// Final stage module: Final AND computation
module final_and (
    input  wire clk,
    input  wire rst_n,
    input  wire in_ab,
    input  wire in_c,
    output reg  out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 1'b0;
        end else begin
            out <= in_ab & in_c;
        end
    end

endmodule