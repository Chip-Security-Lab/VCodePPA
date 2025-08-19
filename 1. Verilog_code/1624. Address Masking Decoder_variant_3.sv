//SystemVerilog
module mask_decoder (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] addr,
    input [7:0] mask,
    output reg [3:0] sel
);

    // Stage 1 registers
    reg req_stage1;
    reg [7:0] addr_stage1;
    reg [7:0] mask_stage1;
    reg valid_stage1;

    // Stage 2 registers
    reg [7:0] masked_addr_stage2;
    reg valid_stage2;

    // Stage 3 registers
    reg [3:0] sel_stage3;
    reg valid_stage3;

    // Stage 1: Input sampling and request detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= 1'b0;
            addr_stage1 <= 8'h0;
            mask_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
        end else begin
            req_stage1 <= req;
            addr_stage1 <= addr;
            mask_stage1 <= mask;
            valid_stage1 <= req && !req_stage1;
        end
    end

    // Stage 2: Address masking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_addr_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
        end else begin
            masked_addr_stage2 <= addr_stage1 & mask_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Selection logic and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
            ack <= 1'b0;
        end else begin
            if (valid_stage2) begin
                case (masked_addr_stage2)
                    8'h00: sel_stage3 <= 4'b0001;
                    8'h10: sel_stage3 <= 4'b0010;
                    8'h20: sel_stage3 <= 4'b0100;
                    8'h30: sel_stage3 <= 4'b1000;
                    default: sel_stage3 <= 4'b0000;
                endcase
                valid_stage3 <= 1'b1;
                ack <= 1'b1;
            end else if (!valid_stage2 && valid_stage3) begin
                ack <= 1'b0;
                valid_stage3 <= 1'b0;
            end
        end
    end

    assign sel = sel_stage3;

endmodule