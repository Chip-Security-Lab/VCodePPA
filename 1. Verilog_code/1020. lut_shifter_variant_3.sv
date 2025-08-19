//SystemVerilog
// Top-level module: Pipelined Hierarchical LUT-based Shifter (Modularized Always Blocks)
module lut_shifter #(parameter W = 4) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [W-1:0]          din,
    input  wire [1:0]            shift,
    output wire [W-1:0]          dout
);

    // Stage 1: Register input data
    reg [W-1:0]                  din_reg_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg_stage1 <= {W{1'b0}};
        end else begin
            din_reg_stage1 <= din;
        end
    end

    // Stage 1: Register shift control
    reg [1:0]                    shift_reg_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 2'b00;
        end else begin
            shift_reg_stage1 <= shift;
        end
    end

    // Stage 2: Parallel shift operations (combinational)
    wire [W-1:0]                 shift_data_0_stage2;
    wire [W-1:0]                 shift_data_1_stage2;
    wire [W-1:0]                 shift_data_2_stage2;
    wire [W-1:0]                 shift_data_3_stage2;

    lut_shift_op #(.W(W), .SHIFT_VAL(0)) u_shift_0 (
        .din(din_reg_stage1),
        .dout(shift_data_0_stage2)
    );

    lut_shift_op #(.W(W), .SHIFT_VAL(1)) u_shift_1 (
        .din(din_reg_stage1),
        .dout(shift_data_1_stage2)
    );

    lut_shift_op #(.W(W), .SHIFT_VAL(2)) u_shift_2 (
        .din(din_reg_stage1),
        .dout(shift_data_2_stage2)
    );

    lut_shift_op #(.W(W), .SHIFT_VAL(3)) u_shift_3 (
        .din(din_reg_stage1),
        .dout(shift_data_3_stage2)
    );

    // Stage 2: Register each shift result
    reg [W-1:0]                  shift_reg_0_stage2;
    reg [W-1:0]                  shift_reg_1_stage2;
    reg [W-1:0]                  shift_reg_2_stage2;
    reg [W-1:0]                  shift_reg_3_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_0_stage2 <= {W{1'b0}};
        end else begin
            shift_reg_0_stage2 <= shift_data_0_stage2;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_1_stage2 <= {W{1'b0}};
        end else begin
            shift_reg_1_stage2 <= shift_data_1_stage2;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_2_stage2 <= {W{1'b0}};
        end else begin
            shift_reg_2_stage2 <= shift_data_2_stage2;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_3_stage2 <= {W{1'b0}};
        end else begin
            shift_reg_3_stage2 <= shift_data_3_stage2;
        end
    end

    // Stage 2: Register shift amount
    reg [1:0]                    shift_amount_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_amount_stage2 <= 2'b00;
        end else begin
            shift_amount_stage2 <= shift_reg_stage1;
        end
    end

    // Stage 3: Select shifted data (combinational)
    reg [W-1:0]                  shifted_data_stage3;
    always @(*) begin
        case (shift_amount_stage2)
            2'd0: shifted_data_stage3 = shift_reg_0_stage2;
            2'd1: shifted_data_stage3 = shift_reg_1_stage2;
            2'd2: shifted_data_stage3 = shift_reg_2_stage2;
            2'd3: shifted_data_stage3 = shift_reg_3_stage2;
            default: shifted_data_stage3 = {W{1'b0}};
        endcase
    end

    // Stage 3: Register output
    reg [W-1:0]                  dout_reg_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg_stage3 <= {W{1'b0}};
        end else begin
            dout_reg_stage3 <= shifted_data_stage3;
        end
    end

    assign dout = dout_reg_stage3;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Shift Operation
// Description: Performs left shift by parameterizable amount.
// -----------------------------------------------------------------------------
module lut_shift_op #(parameter W = 4, parameter SHIFT_VAL = 0) (
    input  wire [W-1:0] din,
    output wire [W-1:0] dout
);

    assign dout = (SHIFT_VAL == 0) ? din :
                  (SHIFT_VAL == 1) ? {din[W-2:0], 1'b0} :
                  (SHIFT_VAL == 2) ? {din[W-3:0], 2'b00} :
                  (SHIFT_VAL == 3) ? {din[W-4:0], 3'b000} :
                  {W{1'b0}};

endmodule