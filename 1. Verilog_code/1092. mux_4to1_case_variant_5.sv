//SystemVerilog
module mux_4to1_pipeline (
    input wire          clk,
    input wire          rst_n,
    input wire  [1:0]   sel,           // Selection input
    input wire  [7:0]   in0, in1, in2, in3, // Data inputs
    output reg  [7:0]   data_out       // Registered output
);

    // Pipeline Stage 1: Register inputs and selection lines
    reg [1:0] sel_stage1;
    reg [7:0] in0_stage1, in1_stage1, in2_stage1, in3_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1  <= 2'b00;
            in0_stage1  <= 8'b0;
            in1_stage1  <= 8'b0;
            in2_stage1  <= 8'b0;
            in3_stage1  <= 8'b0;
        end else begin
            sel_stage1  <= sel;
            in0_stage1  <= in0;
            in1_stage1  <= in1;
            in2_stage1  <= in2;
            in3_stage1  <= in3;
        end
    end

    // Pipeline Stage 2: First level of muxing (pairwise)
    reg [7:0] mux_l0_a_stage2, mux_l0_b_stage2;
    reg [1:0] sel_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_l0_a_stage2 <= 8'b0;
            mux_l0_b_stage2 <= 8'b0;
            sel_stage2      <= 2'b00;
        end else begin
            // Pairwise multiplexing
            mux_l0_a_stage2 <= (sel_stage1[0] == 1'b0) ? in0_stage1 : in1_stage1;
            mux_l0_b_stage2 <= (sel_stage1[0] == 1'b0) ? in2_stage1 : in3_stage1;
            sel_stage2      <= sel_stage1;
        end
    end

    // Pipeline Stage 3: Final muxing
    reg [7:0] mux_final_stage3;
    reg [1:0] sel_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_final_stage3 <= 8'b0;
            sel_stage3       <= 2'b00;
        end else begin
            mux_final_stage3 <= (sel_stage2[1] == 1'b0) ? mux_l0_a_stage2 : mux_l0_b_stage2;
            sel_stage3       <= sel_stage2;
        end
    end

    // Pipeline Stage 4: Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out <= mux_final_stage3;
        end
    end

endmodule