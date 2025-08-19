//SystemVerilog
module Mux2D #(parameter W=4, X=2, Y=2) (
    input clk,
    input rst_n,
    input [W-1:0] matrix [0:X-1][0:Y-1],
    input [$clog2(X)-1:0] x_sel,
    input [$clog2(Y)-1:0] y_sel,
    output reg [W-1:0] element
);

    // Pipeline stage 1: Selection logic
    reg [$clog2(X)-1:0] x_sel_reg_stage1;
    reg [$clog2(Y)-1:0] y_sel_reg_stage1;
    reg [W-1:0] matrix_reg [0:X-1][0:Y-1];

    // Pipeline stage 2: Row selection
    reg [W-1:0] row_data [0:Y-1];
    reg [W-1:0] selected_row_stage2;

    // Pipeline stage 3: Column selection
    reg [W-1:0] selected_element_stage3;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_sel_reg_stage1 <= 0;
            y_sel_reg_stage1 <= 0;
            for (int i = 0; i < X; i++) begin
                for (int j = 0; j < Y; j++) begin
                    matrix_reg[i][j] <= 0;
                end
            end
        end else begin
            x_sel_reg_stage1 <= x_sel;
            y_sel_reg_stage1 <= y_sel;
            for (int i = 0; i < X; i++) begin
                for (int j = 0; j < Y; j++) begin
                    matrix_reg[i][j] <= matrix[i][j];
                end
            end
        end
    end

    // Stage 2: Row selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int j = 0; j < Y; j++) begin
                row_data[j] <= 0;
            end
            selected_row_stage2 <= 0;
        end else begin
            for (int j = 0; j < Y; j++) begin
                row_data[j] <= matrix_reg[x_sel_reg_stage1][j];
            end
            selected_row_stage2 <= x_sel_reg_stage1;
        end
    end

    // Stage 3: Column selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_element_stage3 <= 0;
        end else begin
            selected_element_stage3 <= row_data[y_sel_reg_stage1];
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            element <= 0;
        end else begin
            element <= selected_element_stage3;
        end
    end

endmodule