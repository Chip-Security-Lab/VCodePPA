//SystemVerilog
module rng_triple_lfsr_19(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rnd
);

// Stage 1: Register LFSR states and input control
reg [7:0] lfsr_a_s1, lfsr_b_s1, lfsr_c_s1;
reg       en_s1;

always @(posedge clk) begin
    if (rst) begin
        lfsr_a_s1 <= 8'hFE;
        lfsr_b_s1 <= 8'hBD;
        lfsr_c_s1 <= 8'h73;
        en_s1     <= 1'b0;
    end else begin
        en_s1 <= en;
        if (en) begin
            lfsr_a_s1 <= lfsr_a_s1;
            lfsr_b_s1 <= lfsr_b_s1;
            lfsr_c_s1 <= lfsr_c_s1;
        end
    end
end

// Stage 2: Calculate feedback bits
reg [7:0] lfsr_a_s2, lfsr_b_s2, lfsr_c_s2;
reg       en_s2;
reg       fA_s2, fB_s2, fC_s2;

always @(posedge clk) begin
    if (rst) begin
        lfsr_a_s2 <= 8'hFE;
        lfsr_b_s2 <= 8'hBD;
        lfsr_c_s2 <= 8'h73;
        fA_s2     <= 1'b0;
        fB_s2     <= 1'b0;
        fC_s2     <= 1'b0;
        en_s2     <= 1'b0;
    end else begin
        en_s2 <= en_s1;
        if (en_s1) begin
            lfsr_a_s2 <= lfsr_a_s1;
            lfsr_b_s2 <= lfsr_b_s1;
            lfsr_c_s2 <= lfsr_c_s1;
            fA_s2     <= ^({lfsr_a_s1[7], lfsr_a_s1[3]});
            fB_s2     <= ^({lfsr_b_s1[7], lfsr_b_s1[2]});
            fC_s2     <= ^({lfsr_c_s1[7], lfsr_c_s1[1]});
        end
    end
end

// Stage 3: Update LFSR states with feedback
reg [7:0] lfsr_a_s3, lfsr_b_s3, lfsr_c_s3;
reg       en_s3;

always @(posedge clk) begin
    if (rst) begin
        lfsr_a_s3 <= 8'hFE;
        lfsr_b_s3 <= 8'hBD;
        lfsr_c_s3 <= 8'h73;
        en_s3     <= 1'b0;
    end else begin
        en_s3 <= en_s2;
        if (en_s2) begin
            lfsr_a_s3 <= {lfsr_a_s2[6:0], fA_s2};
            lfsr_b_s3 <= {lfsr_b_s2[6:0], fB_s2};
            lfsr_c_s3 <= {lfsr_c_s2[6:0], fC_s2};
        end
    end
end

// Stage 4: Output random value
always @(posedge clk) begin
    if (rst) begin
        rnd <= 8'b0;
    end else if (en_s3) begin
        rnd <= lfsr_a_s3 ^ lfsr_b_s3 ^ lfsr_c_s3;
    end
end

endmodule