//SystemVerilog
module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] product
);
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] accum;
    reg [WIDTH-1:0] multiplicand;
    reg [1:0] state;  // Reduced state bits
    reg [$clog2(WIDTH)-1:0] bit_count;  // Optimized bit width
    
    // Combined state and counter control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            bit_count <= 0;
        end else begin
            case(state)
                0: begin
                    state <= 1;
                    bit_count <= 0;
                end
                1: begin
                    if (bit_count == WIDTH-1) begin
                        state <= 2;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
                2: state <= 0;
                default: state <= 0;
            endcase
        end
    end
    
    // Optimized multiplier shift
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            multiplier <= b;
        end else if (state == 1) begin
            multiplier <= {1'b0, multiplier[WIDTH-1:1]};
        end
    end
    
    // Optimized multiplicand latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            multiplicand <= a;
        end
    end
    
    // Optimized accumulator with pre-computed shift
    wire [2*WIDTH-1:0] shifted_multiplicand = multiplicand << bit_count;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accum <= 0;
        end else begin
            case(state)
                0: accum <= 0;
                1: begin
                    if (multiplier[0]) begin
                        accum <= accum + shifted_multiplicand;
                    end
                end
                default: accum <= accum;
            endcase
        end
    end
    
    // Optimized product output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            product <= 0;
        end else if (state == 2) begin
            product <= accum;
        end
    end
    
endmodule