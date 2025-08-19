//SystemVerilog
module PartialNOT_valid_ready(
    input wire clk,
    input wire reset_n,
    input wire [15:0] word_in,
    input wire word_in_valid,
    output wire word_in_ready,
    output wire [15:0] modified_out,
    output wire modified_out_valid,
    input wire modified_out_ready
);

    reg [15:0] modified_reg;
    reg modified_valid_reg;

    assign word_in_ready = !modified_valid_reg || modified_out_ready; // Ready when output is not valid or downstream is ready
    assign modified_out = modified_reg;
    assign modified_out_valid = modified_valid_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            modified_reg <= 16'h0000;
            modified_valid_reg <= 1'b0;
        end else begin
            case ({word_in_valid && word_in_ready, modified_valid_reg && modified_out_ready})
                2'b10: begin // word_in_valid && word_in_ready is true, modified_valid_reg && modified_out_ready is false
                    modified_reg[15:8] <= word_in[15:8];
                    modified_reg[7:0] <= ~word_in[7:0];
                    modified_valid_reg <= 1'b1;
                end
                2'b01: begin // word_in_valid && word_in_ready is false, modified_valid_reg && modified_out_ready is true
                    modified_valid_reg <= 1'b0;
                end
                2'b11: begin // Both conditions are true, prioritize input
                     modified_reg[15:8] <= word_in[15:8];
                    modified_reg[7:0] <= ~word_in[7:0];
                    modified_valid_reg <= 1'b1;
                end
                default: begin // 2'b00 or other unexpected cases
                    // No change
                end
            endcase
        end
    end

endmodule