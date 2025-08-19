//SystemVerilog

module bin2sevenseg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  bin_in,
    output wire [6:0]  seg_out_n
);

    // Stage 1: Input Latch
    reg [3:0] bin_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_stage1 <= 4'd0;
        else
            bin_stage1 <= bin_in;
    end

    // Stage 2: Decode logic (combinational, pipelined input)
    reg [6:0] seg_stage2;
    always @(*) begin
        case (bin_stage1)
            4'h0: seg_stage2 = 7'b0000001; // 0
            4'h1: seg_stage2 = 7'b1001111; // 1
            4'h2: seg_stage2 = 7'b0010010; // 2
            4'h3: seg_stage2 = 7'b0000110; // 3
            4'h4: seg_stage2 = 7'b1001100; // 4
            default: seg_stage2 = 7'b1111111; // blank
        endcase
    end

    // Stage 3: Output Register for timing closure
    reg [6:0] seg_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            seg_stage3 <= 7'b1111111;
        else
            seg_stage3 <= seg_stage2;
    end

    assign seg_out_n = seg_stage3;

endmodule