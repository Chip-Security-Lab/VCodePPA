//SystemVerilog
module MuxSyncReg #(parameter W=8, N=4) (
    input clk, rst_n,
    input [N-1:0][W-1:0] data_in,
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] data_out
);

    // Pipeline stage 1: Input selection
    reg [N-1:0][W-1:0] data_in_stage1;
    reg [$clog2(N)-1:0] sel_stage1;
    reg valid_stage1;

    // Pipeline stage 2: Data output
    reg [W-1:0] data_out_stage2;
    reg valid_stage2;

    // Stage 1: Input selection and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            sel_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            sel_stage1 <= sel;
            valid_stage1 <= 1;
        end
    end

    // Stage 2: Data output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                data_out_stage2 <= data_in_stage1[sel_stage1];
                valid_stage2 <= 1;
            end else begin
                valid_stage2 <= 0;
            end
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else begin
            if (valid_stage2) begin
                data_out <= data_out_stage2;
            end
        end
    end

endmodule