//SystemVerilog
module asr_shift #(
    parameter DATA_W = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire [DATA_W-1:0] data_i,
    input wire [$clog2(DATA_W)-1:0] shift_i,
    output reg [DATA_W-1:0] data_o
);

    // Pipeline stage registers
    reg [DATA_W-1:0] data_reg1;
    reg [$clog2(DATA_W)-1:0] shift_reg1;
    reg sign_reg1;

    reg [DATA_W-1:0] shifted_reg2;
    reg [$clog2(DATA_W)-1:0] shift_reg2;
    reg sign_reg2;

    reg [DATA_W-1:0] sign_mask_reg3;
    reg [DATA_W-1:0] result_reg3;

    // Stage 1: Capture inputs and sign
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_reg1 <= {DATA_W{1'b0}};
            shift_reg1 <= {$clog2(DATA_W){1'b0}};
            sign_reg1 <= 1'b0;
        end else begin
            data_reg1 <= data_i;
            shift_reg1 <= shift_i;
            sign_reg1 <= data_i[DATA_W-1];
        end
    end

    // Stage 2: Perform logical right shift, propagate shift and sign
    always @(posedge clk_i) begin
        if (rst_i) begin
            shifted_reg2 <= {DATA_W{1'b0}};
            shift_reg2 <= {$clog2(DATA_W){1'b0}};
            sign_reg2 <= 1'b0;
        end else begin
            shifted_reg2 <= data_reg1 >> shift_reg1;
            shift_reg2 <= shift_reg1;
            sign_reg2 <= sign_reg1;
        end
    end

    // Stage 3: Generate sign mask efficiently using range comparison
    always @(posedge clk_i) begin
        if (rst_i) begin
            sign_mask_reg3 <= {DATA_W{1'b0}};
        end else begin
            // If sign is negative and shift amount != 0, generate mask
            if (sign_reg2 && |shift_reg2) begin
                sign_mask_reg3 <= {DATA_W{1'b1}} << (DATA_W - shift_reg2);
            end else begin
                sign_mask_reg3 <= {DATA_W{1'b0}};
            end
        end
    end

    // Stage 4: Compute result and output
    always @(posedge clk_i) begin
        if (rst_i) begin
            result_reg3 <= {DATA_W{1'b0}};
            data_o <= {DATA_W{1'b0}};
        end else begin
            // Use mask only if sign is negative
            result_reg3 <= shifted_reg2 | sign_mask_reg3;
            data_o <= result_reg3;
        end
    end

endmodule