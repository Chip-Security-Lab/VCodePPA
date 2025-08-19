//SystemVerilog
module variable_slope_triangle(
    input clk_in,
    input reset,
    input [7:0] up_slope_rate,
    input [7:0] down_slope_rate,
    output [7:0] triangle_out
);
    reg direction;
    reg [7:0] counter;
    reg [7:0] triangle_reg;
    
    reg [7:0] triangle_buf1, triangle_buf2;
    reg [7:0] counter_buf1, counter_buf2;
    reg direction_buf1, direction_buf2;
    
    reg b0_1, b0_2;
    reg b1_1, b1_2;
    
    wire counter_ge_up = (counter >= up_slope_rate);
    wire counter_ge_down = (counter >= down_slope_rate);
    
    // Han-Carlson adder signals
    wire [7:0] counter_plus_one;
    wire [7:0] triangle_plus_one;
    wire [7:0] triangle_minus_one;
    
    // Han-Carlson adder implementation
    han_carlson_adder #(.WIDTH(8)) counter_adder (
        .a(counter),
        .b(8'b1),
        .sum(counter_plus_one)
    );
    
    han_carlson_adder #(.WIDTH(8)) triangle_inc_adder (
        .a(triangle_reg),
        .b(8'b1),
        .sum(triangle_plus_one)
    );
    
    han_carlson_adder #(.WIDTH(8)) triangle_dec_adder (
        .a(triangle_reg),
        .b(8'hff),  // -1 in 2's complement
        .sum(triangle_minus_one)
    );
    
    always @(posedge clk_in) begin
        if (reset) begin
            triangle_reg <= 8'b0;
            direction <= 1'b0;
            counter <= 8'b0;
            
            triangle_buf1 <= 8'b0;
            triangle_buf2 <= 8'b0;
            counter_buf1 <= 8'b0;
            counter_buf2 <= 8'b0;
            direction_buf1 <= 1'b0;
            direction_buf2 <= 1'b0;
            b0_1 <= 1'b0;
            b0_2 <= 1'b0;
            b1_1 <= 1'b0;
            b1_2 <= 1'b0;
        end else begin
            counter <= counter_plus_one;
            
            b0_1 <= !direction && counter_ge_up;
            b0_2 <= b0_1;
            
            b1_1 <= direction && counter_ge_down;
            b1_2 <= b1_1;
            
            triangle_buf1 <= triangle_reg;
            triangle_buf2 <= triangle_buf1;
            
            counter_buf1 <= counter;
            counter_buf2 <= counter_buf1;
            
            direction_buf1 <= direction;
            direction_buf2 <= direction_buf1;
            
            if (b0_2) begin
                counter <= 8'b0;
                if (triangle_reg == 8'hff)
                    direction <= 1'b1;
                else
                    triangle_reg <= triangle_plus_one;
            end else if (b1_2) begin
                counter <= 8'b0;
                if (triangle_reg == 8'h00)
                    direction <= 1'b0;
                else
                    triangle_reg <= triangle_minus_one;
            end
        end
    end
    
    assign triangle_out = triangle_buf2;
endmodule

module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g1, p1;
    wire [WIDTH-1:0] g2, p2;
    wire [WIDTH-1:0] g3, p3;
    wire [WIDTH-1:0] g4, p4;
    wire [WIDTH-1:0] g5, p5;
    wire [WIDTH-1:0] g6, p6;
    wire [WIDTH-1:0] g7, p7;
    wire [WIDTH-1:0] g8, p8;
    
    // Pre-computation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Second level
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate
    
    // Third level
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate
    
    // Final sum computation
    assign sum[0] = p[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign sum[i] = p[i] ^ g3[i-1];
        end
    endgenerate
endmodule