//SystemVerilog
module excess3_to_bcd (
    input wire clk,
    input wire rst_n,
    input wire [3:0] excess3_in,
    output reg [3:0] bcd_out,
    output reg valid_out
);

    // Stage 1: Input Latching
    reg [3:0] excess3_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            excess3_stage1 <= 4'b0;
        else
            excess3_stage1 <= excess3_in;
    end

    // Stage 2: Range Validation
    reg valid_range_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_range_stage2 <= 1'b0;
        else
            valid_range_stage2 <= (excess3_stage1[3] == 1'b1) || (excess3_stage1 == 4'h3);
    end

    // Stage 2: Prepare Subtraction Input
    reg [3:0] excess3_for_sub_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            excess3_for_sub_stage2 <= 4'b0;
        else
            excess3_for_sub_stage2 <= excess3_stage1;
    end

    // Stage 3: Subtraction and Output Generation
    reg [3:0] bcd_stage3;
    reg valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_stage3 <= 4'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_range_stage2) begin
                bcd_stage3 <= excess3_for_sub_stage2 - 4'h3;
                valid_stage3 <= 1'b1;
            end else begin
                bcd_stage3 <= 4'h0;
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Output Latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_out <= 4'b0;
            valid_out <= 1'b0;
        end else begin
            bcd_out <= bcd_stage3;
            valid_out <= valid_stage3;
        end
    end

endmodule