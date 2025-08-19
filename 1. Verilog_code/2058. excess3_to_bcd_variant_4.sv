//SystemVerilog
module excess3_to_bcd (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  excess3_in,
    output reg  [3:0]  bcd_out,
    output reg         valid_out
);

    // Stage 1: Input Register
    reg [3:0] excess3_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            excess3_stage1 <= 4'd0;
        else
            excess3_stage1 <= excess3_in;
    end

    // Stage 2: Valid Range Calculation
    reg valid_range_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_range_stage2 <= 1'b0;
        else begin
            valid_range_stage2 <= 
                (excess3_stage1[1] & ~excess3_stage1[3]) |
                (excess3_stage1[1] & ~excess3_stage1[2]) |
                (excess3_stage1[2] & ~excess3_stage1[3]);
        end
    end

    // Stage 2: Data Path Calculation (subtract 3)
    reg [3:0] bcd_candidate_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bcd_candidate_stage2 <= 4'd0;
        else
            bcd_candidate_stage2 <= excess3_stage1 - 4'd3;
    end

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_out   <= 4'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_range_stage2) begin
                bcd_out   <= bcd_candidate_stage2;
                valid_out <= 1'b1;
            end else begin
                bcd_out   <= 4'd0;
                valid_out <= 1'b0;
            end
        end
    end

endmodule