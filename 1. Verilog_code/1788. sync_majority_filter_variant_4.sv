//SystemVerilog
module async_debounce_filter #(
    parameter STABLE_COUNT = 8
)(
    input noisy_signal,
    input [3:0] curr_state,
    output reg [3:0] next_state,
    output clean_signal
);
    wire [3:0] bk_add_result;
    wire [3:0] bk_sub_result;
    wire cin_add = 1'b0;
    wire cin_sub = 1'b1;
    wire [3:0] not_curr_state;
    
    assign not_curr_state = ~curr_state;
    
    brent_kung_adder bk_adder_inst (
        .a(curr_state),
        .b(4'b0001),
        .cin(cin_add),
        .sum(bk_add_result)
    );
    
    brent_kung_adder bk_subber_inst (
        .a(curr_state),
        .b(4'b1111),
        .cin(cin_sub),
        .sum(bk_sub_result)
    );
    
    always @(*) begin
        case({noisy_signal, curr_state})
            {1'b1, 4'b0000}: next_state = bk_add_result;
            {1'b1, 4'b0001}: next_state = bk_add_result;
            {1'b1, 4'b0010}: next_state = bk_add_result;
            {1'b1, 4'b0011}: next_state = bk_add_result;
            {1'b1, 4'b0100}: next_state = bk_add_result;
            {1'b1, 4'b0101}: next_state = bk_add_result;
            {1'b1, 4'b0110}: next_state = bk_add_result;
            {1'b1, 4'b0111}: next_state = bk_add_result;
            {1'b0, 4'b0001}: next_state = bk_sub_result;
            {1'b0, 4'b0010}: next_state = bk_sub_result;
            {1'b0, 4'b0011}: next_state = bk_sub_result;
            {1'b0, 4'b0100}: next_state = bk_sub_result;
            {1'b0, 4'b0101}: next_state = bk_sub_result;
            {1'b0, 4'b0110}: next_state = bk_sub_result;
            {1'b0, 4'b0111}: next_state = bk_sub_result;
            {1'b0, 4'b1000}: next_state = bk_sub_result;
            default: next_state = curr_state;
        endcase
    end
    
    assign clean_signal = (curr_state >= STABLE_COUNT/2) ? 1'b1 : 1'b0;
endmodule

module brent_kung_adder (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum
);
    wire [3:0] g, p;
    wire [3:0] c;
    
    assign g[0] = a[0] & b[0];
    assign g[1] = a[1] & b[1];
    assign g[2] = a[2] & b[2];
    assign g[3] = a[3] & b[3];
    
    assign p[0] = a[0] ^ b[0];
    assign p[1] = a[1] ^ b[1];
    assign p[2] = a[2] ^ b[2];
    assign p[3] = a[3] ^ b[3];
    
    wire g_0_1, p_0_1;
    wire g_2_3, p_2_3;
    wire g_0_3, p_0_3;
    
    assign g_0_1 = g[1] | (p[1] & g[0]);
    assign p_0_1 = p[1] & p[0];
    
    assign g_2_3 = g[3] | (p[3] & g[2]);
    assign p_2_3 = p[3] & p[2];
    
    assign g_0_3 = g_2_3 | (p_2_3 & g_0_1);
    assign p_0_3 = p_2_3 & p_0_1;
    
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g_0_1 | (p_0_1 & cin);
    assign c[3] = g_0_3 | (p_0_3 & cin);
    
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
endmodule