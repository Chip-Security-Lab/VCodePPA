//SystemVerilog
module dual_reset_sync (
    input  wire clock,
    input  wire reset_a_n,
    input  wire reset_b_n,
    output wire synchronized_reset_n
);
    reg meta_stage;
    reg output_stage;
    wire combined_reset_n;

    assign combined_reset_n = reset_a_n & reset_b_n;

    always @(posedge clock or negedge combined_reset_n) begin
        meta_stage    <= (!combined_reset_n) ? 1'b0 : 1'b1;
        output_stage  <= (!combined_reset_n) ? 1'b0 : meta_stage;
    end

    assign synchronized_reset_n = output_stage;
endmodule