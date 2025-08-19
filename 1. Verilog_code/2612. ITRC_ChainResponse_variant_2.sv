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

    // Pipeline stage 1 registers
    reg [WIDTH-1:0] masked_src_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers  
    reg [WIDTH-1:0] masked_src_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [WIDTH-1:0] masked_src_stage3;
    reg valid_stage3;

    // Stage 1: Calculate masked source
    always @(posedge clk) begin
        if (!rst_n) begin
            masked_src_stage1 <= 0;
        end else begin
            masked_src_stage1 <= int_src & ~current_int;
        end
    end

    // Stage 1: Valid signal
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= 1;
        end
    end

    // Stage 2: Data pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            masked_src_stage2 <= 0;
        end else begin
            masked_src_stage2 <= masked_src_stage1;
        end
    end

    // Stage 2: Valid pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Data pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            masked_src_stage3 <= 0;
        end else begin
            masked_src_stage3 <= masked_src_stage2;
        end
    end

    // Stage 3: Valid pipeline
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end

    // Output stage: Reset and ACK handling
    always @(posedge clk) begin
        if (!rst_n) begin
            current_int <= 0;
        end else if (ack) begin
            current_int <= {1'b0, current_int[WIDTH-1:1]};
        end
    end

    // Output stage: New interrupt handling
    always @(posedge clk) begin
        if (rst_n && !ack && !current_int[0] && valid_stage3) begin
            current_int <= masked_src_stage3 ^ (masked_src_stage3 - 1);
        end
    end

endmodule