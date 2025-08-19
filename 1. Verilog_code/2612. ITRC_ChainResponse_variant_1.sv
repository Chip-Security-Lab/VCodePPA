//SystemVerilog
module ITRC_ChainResponse #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input ack,
    output reg [WIDTH-1:0] current_int
);

    // Stage registers
    reg [WIDTH-1:0] masked_src_stage1;
    reg [WIDTH-1:0] masked_src_stage2;
    reg [WIDTH-1:0] masked_src_stage3;
    reg [WIDTH-1:0] current_int_stage1;
    reg [WIDTH-1:0] current_int_stage2;
    reg [WIDTH-1:0] current_int_stage3;
    reg ack_stage1;
    reg ack_stage2;
    reg ack_stage3;

    // Stage 1: Input masking and registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_src_stage1 <= 0;
        end else begin
            masked_src_stage1 <= int_src & ~current_int;
        end
    end

    // Stage 1: Current interrupt registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_int_stage1 <= 0;
        end else begin
            current_int_stage1 <= current_int;
        end
    end

    // Stage 1: Acknowledge registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack_stage1 <= 0;
        end else begin
            ack_stage1 <= ack;
        end
    end

    // Stage 2: Pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_src_stage2 <= 0;
            current_int_stage2 <= 0;
            ack_stage2 <= 0;
        end else begin
            masked_src_stage2 <= masked_src_stage1;
            current_int_stage2 <= current_int_stage1;
            ack_stage2 <= ack_stage1;
        end
    end

    // Stage 3: Pipeline registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_src_stage3 <= 0;
            current_int_stage3 <= 0;
            ack_stage3 <= 0;
        end else begin
            masked_src_stage3 <= masked_src_stage2;
            current_int_stage3 <= current_int_stage2;
            ack_stage3 <= ack_stage2;
        end
    end

    // Stage 4: Output generation - Acknowledge handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_int <= 0;
        end else if (ack_stage3) begin
            current_int <= {1'b0, current_int_stage3[WIDTH-1:1]};
        end
    end

    // Stage 4: Output generation - Interrupt handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset handled in acknowledge block
        end else if (!ack_stage3) begin
            if (!current_int_stage3[0]) begin
                current_int <= masked_src_stage3 ^ (masked_src_stage3 - 1);
            end else begin
                current_int <= current_int_stage3;
            end
        end
    end

endmodule