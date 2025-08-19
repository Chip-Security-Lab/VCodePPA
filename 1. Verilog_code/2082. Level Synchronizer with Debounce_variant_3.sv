//SystemVerilog
module level_sync_debounce #(parameter DEBOUNCE_COUNT = 3) (
    input wire src_clk,
    input wire dst_clk,
    input wire rst,
    input wire level_in,
    output reg level_out
);
    reg level_meta_d, level_sync_d;
    reg level_sync, level_sync_prev;
    reg [3:0] stable_count;

    // 4-bit carry lookahead adder for increment operation
    wire [3:0] stable_count_next;
    wire carry_out;

    carry_lookahead_adder_4bit cla_inst (
        .a(stable_count),
        .b(4'b0001),
        .cin(1'b0),
        .sum(stable_count_next),
        .cout(carry_out)
    );

    // Move synchronizer registers after the first stage of logic
    wire level_in_comb;
    assign level_in_comb = level_in;

    always @ (posedge dst_clk) begin
        if (rst) begin
            level_meta_d <= 1'b0;
            level_sync_d <= 1'b0;
        end else begin
            level_meta_d <= level_in_comb;
            level_sync_d <= level_meta_d;
        end
    end

    // Register after combinational logic (retimed)
    always @ (posedge dst_clk) begin
        if (rst) begin
            level_sync <= 1'b0;
        end else begin
            level_sync <= level_sync_d;
        end
    end

    // Debounce logic
    always @ (posedge dst_clk) begin
        if (rst) begin
            stable_count <= 4'd0;
            level_sync_prev <= 1'b0;
            level_out <= 1'b0;
        end else begin
            level_sync_prev <= level_sync;

            if (level_sync != level_sync_prev) begin
                stable_count <= 4'd0;
            end else if (stable_count < DEBOUNCE_COUNT) begin
                stable_count <= stable_count_next;
            end else if (stable_count == DEBOUNCE_COUNT) begin
                level_out <= level_sync;
            end
        end
    end
endmodule

module carry_lookahead_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [3:0] p, g;
    wire c1, c2, c3, c4;

    assign p = a ^ b;          // propagate
    assign g = a & b;          // generate

    assign c1 = g[0] | (p[0] & cin);
    assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);

    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c1;
    assign sum[2] = p[2] ^ c2;
    assign sum[3] = p[3] ^ c3;
    assign cout   = c4;
endmodule