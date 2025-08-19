//SystemVerilog
module sync_mux_with_reset(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input sel, en,
    output reg [31:0] result
);

    // Stage 1: MUX operation
    reg [31:0] mux_out_stage1;
    reg valid_stage1;
    
    // Stage 2: Register operation
    reg [31:0] data_stage2;
    reg valid_stage2;
    
    // Stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            mux_out_stage1 <= sel ? data_b : data_a;
            valid_stage1 <= en;
        end
    end
    
    // Stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 32'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= mux_out_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 32'b0;
        else if (valid_stage2)
            result <= data_stage2;
    end

endmodule