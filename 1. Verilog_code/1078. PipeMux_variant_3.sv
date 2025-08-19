//SystemVerilog
module PipeMux #(
    parameter DW = 8,           // Data width
    parameter STAGES = 4        // Pipeline depth
)(
    input                  clk,
    input                  rst,
    input        [3:0]     sel,
    input  [(16*DW)-1:0]   din,
    output [DW-1:0]        dout
);

    // Pipeline stage registers
    reg [DW-1:0] data_stage1;
    reg [DW-1:0] data_stage2;
    reg [DW-1:0] data_stage3;
    reg [DW-1:0] data_stage4;

    // Pipeline valid signal registers
    reg          valid_stage1;
    reg          valid_stage2;
    reg          valid_stage3;
    reg          valid_stage4;

    // Stage 1: Input selection and valid generation
    // ---------------------------------------------
    // Handles the input selection based on 'sel' and generates valid for stage 1.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1  <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1  <= din[(sel*DW) +: DW];
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Data and valid transfer from stage 1 to stage 2
    // --------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage2  <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2  <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Data and valid transfer from stage 2 to stage 3
    // --------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage3  <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            data_stage3  <= data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Data and valid transfer from stage 3 to stage 4
    // --------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage4  <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            data_stage4  <= data_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output selection logic based on pipeline depth
    // ----------------------------------------------
    // Selects the output from the correct pipeline stage based on the STAGES parameter.
    reg [DW-1:0] dout_reg;
    always @(*) begin
        if (STAGES == 1) begin
            dout_reg = data_stage1;
        end else if (STAGES == 2) begin
            dout_reg = data_stage2;
        end else if (STAGES == 3) begin
            dout_reg = data_stage3;
        end else begin
            dout_reg = data_stage4;
        end
    end
    assign dout = dout_reg;

endmodule