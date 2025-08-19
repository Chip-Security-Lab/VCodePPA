//SystemVerilog
module dual_reset_sync (
    input  wire clock,
    input  wire reset_a_n,
    input  wire reset_b_n,
    output wire synchronized_reset_n
);
    reg  meta_stage_reg;
    reg  pre_sync_reg;
    wire combined_reset_n;
    wire meta_stage_d;

    assign combined_reset_n = reset_a_n & reset_b_n;

    assign meta_stage_d = 1'b1;

    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            meta_stage_reg <= 1'b0;
        end else begin
            meta_stage_reg <= meta_stage_d;
        end
    end

    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            pre_sync_reg <= 1'b0;
        end else begin
            pre_sync_reg <= meta_stage_reg;
        end
    end

    assign synchronized_reset_n = pre_sync_reg;
endmodule