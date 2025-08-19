//SystemVerilog
module subpixel_render (
    input clk,
    input rst_n,
    input [7:0] px1, px2,
    input req_in,
    output reg ack_in,
    output reg [7:0] px_out,
    output reg req_out,
    input ack_out
);
    reg [7:0] px1_reg, px2_reg;
    wire [7:0] px1_x3;
    wire [9:0] sum_value;
    reg [1:0] state;
    
    localparam IDLE = 2'b00,
               PROCESSING = 2'b01,
               WAITING_ACK = 2'b10;
    
    // Control logic for req-ack protocol
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack_in <= 1'b0;
            req_out <= 1'b0;
            px1_reg <= 8'b0;
            px2_reg <= 8'b0;
            px_out <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req_in) begin
                        px1_reg <= px1;
                        px2_reg <= px2;
                        ack_in <= 1'b1;
                        state <= PROCESSING;
                    end
                end
                
                PROCESSING: begin
                    ack_in <= 1'b0;
                    px_out <= sum_value >> 2;
                    req_out <= 1'b1;
                    state <= WAITING_ACK;
                end
                
                WAITING_ACK: begin
                    if (ack_out) begin
                        req_out <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    karatsuba_mult_8bit karatsuba_mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a(px1_reg),
        .b(8'd3),
        .req(state == PROCESSING),
        .ack(mult_ack),
        .product(px1_x3)
    );
    
    assign sum_value = px1_x3 + px2_reg;
endmodule

module karatsuba_mult_8bit (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input req,
    output reg ack,
    output reg [7:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] p1, p2, p3;
    wire [7:0] term1, term2, term3;
    wire [15:0] full_product;
    
    reg [1:0] state;
    
    localparam IDLE = 2'b00,
               COMPUTING = 2'b01,
               DONE = 2'b10;
    
    // Control logic for req-ack protocol
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack <= 1'b0;
            product <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= COMPUTING;
                    end
                    ack <= 1'b0;
                end
                
                COMPUTING: begin
                    product <= full_product[7:0];
                    state <= DONE;
                end
                
                DONE: begin
                    ack <= 1'b1;
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Split inputs into high and low parts
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Calculate three products according to Karatsuba algorithm
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    assign p3 = (a_high + a_low) * (b_high + b_low);
    
    // Calculate the terms for the final result
    assign term1 = p1 << 8;
    assign term2 = (p3 - p1 - p2) << 4;
    assign term3 = p2;
    
    // Combine the terms to get the final result
    assign full_product = term1 + term2 + term3;
endmodule