//SystemVerilog
module mux_4to1_case (
    input  wire        clk,                // Clock for pipelining
    input  wire        rst_n,              // Active-low synchronous reset
    input  wire [1:0]  sel,                // 2-bit selection lines
    input  wire [7:0]  in0, in1, in2, in3, // Data inputs
    output reg  [7:0]  data_out            // Output data
);

    // Stage 1: Register selection and inputs
    reg [1:0] sel_pipeline_stage1;
    reg [7:0] in0_pipeline_stage1, in1_pipeline_stage1, in2_pipeline_stage1, in3_pipeline_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_pipeline_stage1  <= 2'b00;
            in0_pipeline_stage1  <= 8'b0;
            in1_pipeline_stage1  <= 8'b0;
            in2_pipeline_stage1  <= 8'b0;
            in3_pipeline_stage1  <= 8'b0;
        end else begin
            sel_pipeline_stage1  <= sel;
            in0_pipeline_stage1  <= in0;
            in1_pipeline_stage1  <= in1;
            in2_pipeline_stage1  <= in2;
            in3_pipeline_stage1  <= in3;
        end
    end

    // Stage 2: Partial mux result (register the selected data input)
    reg [7:0] mux_selected_data_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_selected_data_stage2 <= 8'b0;
        end else begin
            case (sel_pipeline_stage1)
                2'b00: mux_selected_data_stage2 <= in0_pipeline_stage1;
                2'b01: mux_selected_data_stage2 <= in1_pipeline_stage1;
                2'b10: mux_selected_data_stage2 <= in2_pipeline_stage1;
                2'b11: mux_selected_data_stage2 <= in3_pipeline_stage1;
                default: mux_selected_data_stage2 <= 8'b0;
            endcase
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out <= mux_selected_data_stage2;
        end
    end

endmodule