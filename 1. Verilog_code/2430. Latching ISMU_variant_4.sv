//SystemVerilog
module latch_ismu #(parameter WIDTH = 16)(
    input wire i_clk, i_rst_b,
    input wire [WIDTH-1:0] i_int_src,
    input wire i_latch_en,
    input wire [WIDTH-1:0] i_int_clr,
    output reg [WIDTH-1:0] o_latched_int
);
    wire [WIDTH-1:0] int_set;
    wire [WIDTH-1:0] next_int_state;
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] sub_result;
    
    // Apply latch enable mask to interrupt sources
    assign int_set = i_int_src & {WIDTH{i_latch_en}};
    
    // First-level borrow generation
    assign borrow[0] = i_int_clr[0] & ~(o_latched_int[0] | int_set[0]);
    
    // Borrow propagation chain for borrow-based subtraction
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : borrow_chain
            assign borrow[i] = i_int_clr[i] & ~(o_latched_int[i] | int_set[i]) | 
                              (i_int_clr[i-1] & borrow[i-1]);
        end
    endgenerate
    
    // Implement borrow-based subtraction
    // Subtract cleared interrupts from latched interrupts with borrow propagation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : subtractor
            assign sub_result[i] = (o_latched_int[i] | int_set[i]) ^ i_int_clr[i] ^ 
                                  (i > 0 ? borrow[i-1] : 1'b0);
        end
    endgenerate
    
    // Calculate next state with borrow-based subtraction
    assign next_int_state = (o_latched_int | int_set) & ~i_int_clr;
    
    // Register update logic
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b)
            o_latched_int <= {WIDTH{1'b0}};
        else
            o_latched_int <= next_int_state;
    end
endmodule