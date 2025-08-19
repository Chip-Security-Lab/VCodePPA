//SystemVerilog
module run_length_encoder_valid_ready #(
    parameter DATA_WIDTH = 1,
    parameter COUNT_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  data_valid,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [COUNT_WIDTH-1:0] count_out,
    output reg                   data_bit_out,
    output reg                   valid_out,
    input  wire                  ready_in,
    output wire                  ready_out
);

    reg [COUNT_WIDTH-1:0] counter;
    reg [DATA_WIDTH-1:0]  previous_data_bit;
    reg                   output_hold_valid;
    reg [COUNT_WIDTH-1:0] output_hold_count;
    reg [DATA_WIDTH-1:0]  output_hold_bit;

    wire flush_condition;
    wire [COUNT_WIDTH-1:0] counter_sub_result;
    wire counter_is_max;
    wire data_bit_changed;

    assign counter_is_max = (counter == {COUNT_WIDTH{1'b1}});
    assign data_bit_changed = (data_in != previous_data_bit);
    assign flush_condition = counter_is_max | data_bit_changed;

    assign ready_out = (~valid_out) | (valid_out & ready_in);

    // Parallel Prefix Subtractor for 8-bit counter - 8'b1111_1111
    parallel_prefix_subtractor_8b u_parallel_prefix_subtractor_8b (
        .a      (counter),
        .b      (8'b1111_1111),
        .diff   (counter_sub_result)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter           <= { {(COUNT_WIDTH-1){1'b0}}, 1'b1 };
            previous_data_bit <= {DATA_WIDTH{1'b0}};
            valid_out         <= 1'b0;
            count_out         <= {COUNT_WIDTH{1'b0}};
            data_bit_out      <= {DATA_WIDTH{1'b0}};
            output_hold_valid <= 1'b0;
            output_hold_count <= {COUNT_WIDTH{1'b0}};
            output_hold_bit   <= {DATA_WIDTH{1'b0}};
        end else begin
            // Output handshake
            if (valid_out && ready_in)
                valid_out <= 1'b0;

            // Data path
            if (data_valid && ready_out) begin
                if (flush_condition) begin
                    output_hold_count <= counter;
                    output_hold_bit   <= previous_data_bit;
                    output_hold_valid <= 1'b1;
                    counter           <= { {(COUNT_WIDTH-1){1'b0}}, 1'b1 };
                end else begin
                    // Binary two's complement addition for increment
                    counter <= counter + 1'b1;
                end
                previous_data_bit <= data_in;
            end

            // Transfer output if ready and holding data
            if (output_hold_valid && (~valid_out || (valid_out && ready_in))) begin
                count_out         <= output_hold_count;
                data_bit_out      <= output_hold_bit;
                valid_out         <= 1'b1;
                output_hold_valid <= 1'b0;
            end
        end
    end

endmodule

// 8-bit Parallel Prefix Subtractor Module (a - b)
module parallel_prefix_subtractor_8b (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff
);

    wire [7:0] b_inv;
    wire [7:0] p, g;
    wire [7:0] c;

    assign b_inv = ~b;
    assign p = a ^ b_inv;
    assign g = a & b_inv;

    // Parallel prefix computation for borrow (Kogge-Stone style)
    wire [7:0] g1, p1, g2, p2, g3, p3;

    // Stage 1
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];

    // Stage 2
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];

    // Stage 3
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3] | (p2[3] & g2[0]);
    assign p3[3] = p2[3] & p2[0];
    assign g3[4] = g2[4] | (p2[4] & g2[1]);
    assign p3[4] = p2[4] & p2[1];
    assign g3[5] = g2[5] | (p2[5] & g2[2]);
    assign p3[5] = p2[5] & p2[2];
    assign g3[6] = g2[6] | (p2[6] & g2[3]);
    assign p3[6] = p2[6] & p2[3];
    assign g3[7] = g2[7] | (p2[7] & g2[4]);
    assign p3[7] = p2[7] & p2[4];

    // Borrow chain
    assign c[0] = 1'b1; // Subtraction: initial borrow is 1 for two's complement
    assign c[1] = g3[0] | (p3[0] & c[0]);
    assign c[2] = g3[1] | (p3[1] & c[1]);
    assign c[3] = g3[2] | (p3[2] & c[2]);
    assign c[4] = g3[3] | (p3[3] & c[3]);
    assign c[5] = g3[4] | (p3[4] & c[4]);
    assign c[6] = g3[5] | (p3[5] & c[5]);
    assign c[7] = g3[6] | (p3[6] & c[6]);

    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ c[1];
    assign diff[2] = p[2] ^ c[2];
    assign diff[3] = p[3] ^ c[3];
    assign diff[4] = p[4] ^ c[4];
    assign diff[5] = p[5] ^ c[5];
    assign diff[6] = p[6] ^ c[6];
    assign diff[7] = p[7] ^ c[7];

endmodule