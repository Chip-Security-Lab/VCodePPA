//SystemVerilog
// Han-Carlson Adder implementation
module han_carlson_adder (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] p, g;
    wire [3:0] p_group, g_group;
    wire [1:0] p_final, g_final;
    wire cout_temp;

    // Generate P and G terms
    assign p = a ^ b;
    assign g = a & b;

    // First level grouping
    assign p_group[0] = p[0] & p[1];
    assign g_group[0] = g[1] | (p[1] & g[0]);
    assign p_group[1] = p[2] & p[3];
    assign g_group[1] = g[3] | (p[3] & g[2]);
    assign p_group[2] = p[4] & p[5];
    assign g_group[2] = g[5] | (p[5] & g[4]);
    assign p_group[3] = p[6] & p[7];
    assign g_group[3] = g[7] | (p[7] & g[6]);

    // Second level grouping
    assign p_final[0] = p_group[0] & p_group[1];
    assign g_final[0] = g_group[1] | (p_group[1] & g_group[0]);
    assign p_final[1] = p_group[2] & p_group[3];
    assign g_final[1] = g_group[3] | (p_group[3] & g_group[2]);

    // Final carry generation
    assign cout_temp = g_final[1] | (p_final[1] & g_final[0]) | 
                      (p_final[1] & p_final[0] & cin);
    assign cout = cout_temp;

    // Sum generation
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ (g[0] | (p[0] & cin));
    assign sum[2] = p[2] ^ (g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin));
    assign sum[3] = p[3] ^ (g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | 
                          (p[2] & p[1] & p[0] & cin));
    assign sum[4] = p[4] ^ (g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | 
                          (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin));
    assign sum[5] = p[5] ^ (g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | 
                          (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | 
                          (p[4] & p[3] & p[2] & p[1] & p[0] & cin));
    assign sum[6] = p[6] ^ (g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | 
                          (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | 
                          (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                          (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin));
    assign sum[7] = p[7] ^ (g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | 
                          (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | 
                          (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                          (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                          (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin));
endmodule

// Decoder submodule
module decoder_unit (
    input [2:0] addr_in,
    output reg [7:0] onehot_out
);
    always @(*) begin
        onehot_out = (8'b00000001 << addr_in);
    end
endmodule

// Encoder submodule 
module encoder_unit (
    input [7:0] onehot_in,
    output reg [2:0] addr_out,
    output reg error
);
    integer i;
    always @(*) begin
        error = 1'b1;
        addr_out = 3'b000;
        
        for (i = 0; i < 8; i = i + 1)
            if (onehot_in[i]) begin
                addr_out = i[2:0];
                error = ~(onehot_in == (8'b1 << i));
            end
    end
endmodule

// Top level module with Req-Ack interface
module bidir_decoder (
    input clk,
    input rst_n,
    input req,
    input decode_mode,
    input [2:0] addr_in,
    input [7:0] onehot_in,
    output reg ack,
    output reg [2:0] addr_out,
    output reg [7:0] onehot_out,
    output reg error
);

    wire [7:0] decoder_onehot;
    wire [2:0] encoder_addr;
    wire encoder_error;
    wire [7:0] sum_result;
    wire carry_out;
    reg req_d;
    reg [2:0] addr_in_reg;
    reg [7:0] onehot_in_reg;
    reg decode_mode_reg;

    // Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_d <= 1'b0;
            addr_in_reg <= 3'b0;
            onehot_in_reg <= 8'b0;
            decode_mode_reg <= 1'b0;
        end else if (req && !ack) begin
            req_d <= req;
            addr_in_reg <= addr_in;
            onehot_in_reg <= onehot_in;
            decode_mode_reg <= decode_mode;
        end
    end

    // Generate ack
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ack <= 1'b0;
        else if (req && !ack)
            ack <= 1'b1;
        else if (!req && ack)
            ack <= 1'b0;
    end

    decoder_unit decoder_inst (
        .addr_in(addr_in_reg),
        .onehot_out(decoder_onehot)
    );

    encoder_unit encoder_inst (
        .onehot_in(onehot_in_reg),
        .addr_out(encoder_addr),
        .error(encoder_error)
    );

    han_carlson_adder adder_inst (
        .a(decoder_onehot),
        .b(onehot_in_reg),
        .cin(1'b0),
        .sum(sum_result),
        .cout(carry_out)
    );

    // Register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out <= 8'b0;
            addr_out <= 3'b0;
            error <= 1'b0;
        end else if (req && !ack) begin
            onehot_out <= decode_mode_reg ? decoder_onehot : sum_result;
            addr_out <= decode_mode_reg ? 3'b000 : encoder_addr;
            error <= decode_mode_reg ? 1'b0 : encoder_error;
        end
    end

endmodule