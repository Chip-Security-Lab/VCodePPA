//SystemVerilog
module data_valid_sync #(parameter WIDTH = 32) (
    input  wire                  src_clk,
    input  wire                  dst_clk,
    input  wire                  reset_n,
    input  wire [WIDTH-1:0]      data_in,
    input  wire                  valid_in,
    output wire                  ready_out,
    output reg  [WIDTH-1:0]      data_out,
    output reg                   valid_out,
    input  wire                  ready_in
);
    reg req_src, ack_src;
    reg req_meta, req_dst;
    reg ack_meta, ack_dst;
    reg [WIDTH-1:0] data_reg;

    // Example usage of 8-bit parallel prefix subtractor
    wire [7:0] sub_a, sub_b;
    wire [7:0] sub_result;
    wire       sub_borrow_out;

    assign sub_a = data_in[7:0];
    assign sub_b = data_reg[7:0];

    parallel_prefix_subtractor_8bit u_pps8 (
        .minuend(sub_a),
        .subtrahend(sub_b),
        .difference(sub_result),
        .borrow_out(sub_borrow_out)
    );

    // Source clock domain logic
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_src   <= 1'b0;
            ack_src   <= 1'b0;
            ack_meta  <= 1'b0;
            data_reg  <= {WIDTH{1'b0}};
        end else begin
            ack_meta <= ack_dst;
            ack_src  <= ack_meta;

            if (valid_in && !req_src && (ack_src == req_src)) begin
                data_reg <= data_in;
                req_src  <= ~req_src;
            end
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_meta   <= 1'b0;
            req_dst    <= 1'b0;
            ack_dst    <= 1'b0;
            valid_out  <= 1'b0;
            data_out   <= {WIDTH{1'b0}};
        end else begin
            req_meta <= req_src;
            req_dst  <= req_meta;

            if (req_dst != ack_dst) begin
                if (ready_in) begin
                    data_out[7:0]   <= sub_result;
                    data_out[WIDTH-1:8] <= data_reg[WIDTH-1:8];
                    valid_out       <= 1'b1;
                    ack_dst         <= req_dst;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

    assign ready_out = (req_src == ack_src);

endmodule

// 8-bit Parallel Prefix Subtractor (Kogge-Stone style)
module parallel_prefix_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] g, p, c;
    wire [7:0] b;

    assign b = ~subtrahend;
    assign p = minuend ^ b;
    assign g = ~minuend & b;

    // Prefix computation for borrow
    assign c[0] = 1'b1; // Start with borrow_in = 1 for subtraction (as in two's complement)
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign borrow_out = g[7] | (p[7] & c[7]);

    assign difference[0] = minuend[0] ^ b[0] ^ c[0];
    assign difference[1] = minuend[1] ^ b[1] ^ c[1];
    assign difference[2] = minuend[2] ^ b[2] ^ c[2];
    assign difference[3] = minuend[3] ^ b[3] ^ c[3];
    assign difference[4] = minuend[4] ^ b[4] ^ c[4];
    assign difference[5] = minuend[5] ^ b[5] ^ c[5];
    assign difference[6] = minuend[6] ^ b[6] ^ c[6];
    assign difference[7] = minuend[7] ^ b[7] ^ c[7];

endmodule