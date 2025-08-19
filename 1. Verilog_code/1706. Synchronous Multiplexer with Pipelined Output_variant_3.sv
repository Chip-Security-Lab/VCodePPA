//SystemVerilog
module pipeline_mux(
    input clk, resetn,
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    output reg [15:0] pipe_out
);

    // Pipeline registers
    reg [15:0] stage1_data;
    reg [15:0] stage2_data;
    reg [1:0] stage1_sel;
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Input selection
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            stage1_data <= 16'h0;
            stage1_sel <= 2'b0;
            valid_stage1 <= 1'b0;
        end else begin
            case (sel)
                2'b00: stage1_data <= in1;
                2'b01: stage1_data <= in2;
                2'b10: stage1_data <= in3;
                2'b11: stage1_data <= in4;
            endcase
            stage1_sel <= sel;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Data forwarding
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            stage2_data <= 16'h0;
            valid_stage2 <= 1'b0;
        end else begin
            stage2_data <= stage1_data;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            pipe_out <= 16'h0;
        end else begin
            pipe_out <= stage2_data;
        end
    end

endmodule