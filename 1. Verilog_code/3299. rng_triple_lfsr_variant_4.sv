//SystemVerilog
module rng_triple_lfsr_19_valid_ready #(
    parameter DATA_WIDTH = 8
)(
    input                  clk,
    input                  rst,
    input                  in_valid,
    output                 in_ready,
    input                  out_ready,
    output reg [DATA_WIDTH-1:0] out_data,
    output reg             out_valid
);

    reg [DATA_WIDTH-1:0] lfsr_a, lfsr_b, lfsr_c;
    wire feedback_a, feedback_b, feedback_c;
    wire handshake;

    assign feedback_a = lfsr_a[7] ^ lfsr_a[3];
    assign feedback_b = lfsr_b[7] ^ lfsr_b[2];
    assign feedback_c = lfsr_c[7] ^ lfsr_c[1];

    assign handshake = in_valid && in_ready;
    assign in_ready = !rst && (!out_valid || (out_valid && out_ready));

    always @(posedge clk) begin
        if (rst) begin
            lfsr_a    <= 8'hFE;
            lfsr_b    <= 8'hBD;
            lfsr_c    <= 8'h73;
            out_data  <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (handshake) begin
                lfsr_a    <= {lfsr_a[6:0], feedback_a};
                lfsr_b    <= {lfsr_b[6:0], feedback_b};
                lfsr_c    <= {lfsr_c[6:0], feedback_c};
                out_data  <= lfsr_a ^ lfsr_b ^ lfsr_c;
                out_valid <= 1'b1;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule