//SystemVerilog
module cordic_sine(
    input clock,
    input resetn,
    input req,
    output reg ack,
    input [7:0] angle_step,
    output reg [9:0] sine_output
);
    reg [9:0] x, y;
    reg [7:0] angle;
    reg [2:0] state;
    wire [9:0] manchester_result;
    reg req_reg;
    
    // 曼彻斯特进位链加法器子模块
    manchester_carry_adder #(10) mc_adder (
        .a(y),
        .b((angle < 8'd128) ? (x >> 3) : (~(x >> 3) + 1'b1)),
        .sum(manchester_result)
    );
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x <= 10'd307;       // ~0.6*512
            y <= 10'd0;
            angle <= 8'd0;
            state <= 3'd0;
            sine_output <= 10'd0;
            ack <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            req_reg <= req;
            case (state)
                3'd0: begin
                    if (req && !req_reg) begin
                        angle <= angle + angle_step;
                        state <= 3'd1;
                        ack <= 1'b1;
                    end else begin
                        ack <= 1'b0;
                    end
                end
                3'd1: begin
                    y <= manchester_result;
                    state <= 3'd2;
                    ack <= 1'b0;
                end
                3'd2: begin
                    sine_output <= y;
                    state <= 3'd0;
                    ack <= 1'b0;
                end
                default: begin
                    state <= 3'd0;
                    ack <= 1'b0;
                end
            endcase
        end
    end
endmodule

module manchester_carry_adder #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] c;
    
    assign c[0] = 1'b0;
    assign p = a ^ b;
    assign g = a & b;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: carry_chain
            wire [i:0] carry_chain_i;
            assign carry_chain_i[0] = g[0];
            
            genvar j;
            for (j = 1; j <= i; j = j + 1) begin: chain_stage
                assign carry_chain_i[j] = g[j] | (p[j] & carry_chain_i[j-1]);
            end
            
            assign c[i+1] = carry_chain_i[i];
        end
    endgenerate
    
    assign sum = p ^ c[WIDTH-1:0];
endmodule