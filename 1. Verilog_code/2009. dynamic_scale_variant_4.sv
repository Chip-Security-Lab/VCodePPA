//SystemVerilog
// Top-level module: dynamic_scale_pipeline
// Function: Structured pipelined dynamic barrel shifter with clear dataflow and modular hierarchy

module dynamic_scale_pipeline #(
    parameter W = 24
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [W-1:0]           data_in,
    input  wire [4:0]             shift_ctrl,
    output wire [W-1:0]           data_out
);

    // Stage 0: Input Registering
    reg [W-1:0]   data_in_stage0;
    reg [4:0]     shift_ctrl_stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage0    <= {W{1'b0}};
            shift_ctrl_stage0 <= 5'b0;
        end else begin
            data_in_stage0    <= data_in;
            shift_ctrl_stage0 <= shift_ctrl;
        end
    end

    // Stage 1: Decode shift direction and amount
    wire          shift_is_left_stage1;
    wire [4:0]    shift_amount_stage1;
    shift_direction_decode #(.WIDTH(5)) u_shift_dir_decode (
        .shift_in     (shift_ctrl_stage0),
        .shift_dir    (shift_is_left_stage1),
        .shift_amt    (shift_amount_stage1)
    );

    // Register decode outputs
    reg           shift_is_left_stage1_r;
    reg [4:0]     shift_amount_stage1_r;
    reg [W-1:0]   data_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1          <= {W{1'b0}};
            shift_is_left_stage1_r  <= 1'b0;
            shift_amount_stage1_r   <= 5'b0;
        end else begin
            data_in_stage1          <= data_in_stage0;
            shift_is_left_stage1_r  <= shift_is_left_stage1;
            shift_amount_stage1_r   <= shift_amount_stage1;
        end
    end

    // Stage 2: Barrel shift
    wire [W-1:0]  left_shifted_stage2;
    wire [W-1:0]  right_shifted_stage2;

    barrel_left_shifter #(.W(W)) u_left_shifter (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (data_in_stage1),
        .shift_amt   (shift_amount_stage1_r),
        .data_out    (left_shifted_stage2)
    );

    barrel_right_shifter #(.W(W)) u_right_shifter (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_in     (data_in_stage1),
        .shift_amt   (shift_amount_stage1_r),
        .data_out    (right_shifted_stage2)
    );

    // Register shift results and direction
    reg [W-1:0]   left_shifted_stage2_r;
    reg [W-1:0]   right_shifted_stage2_r;
    reg           shift_is_left_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shifted_stage2_r  <= {W{1'b0}};
            right_shifted_stage2_r <= {W{1'b0}};
            shift_is_left_stage2   <= 1'b0;
        end else begin
            left_shifted_stage2_r  <= left_shifted_stage2;
            right_shifted_stage2_r <= right_shifted_stage2;
            shift_is_left_stage2   <= shift_is_left_stage1_r;
        end
    end

    // Stage 3: Output selection and register
    reg [W-1:0]   data_out_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out_stage3 <= {W{1'b0}};
        else
            data_out_stage3 <= shift_is_left_stage2 ? left_shifted_stage2_r : right_shifted_stage2_r;
    end

    assign data_out = data_out_stage3;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_direction_decode
// Function: Decodes shift direction and computes effective shift amount
// -----------------------------------------------------------------------------
module shift_direction_decode #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] shift_in,
    output wire              shift_dir,   // 1: left shift, 0: right shift
    output wire [WIDTH-1:0]  shift_amt
);
    assign shift_dir = shift_in[WIDTH-1];
    assign shift_amt = shift_in[WIDTH-1] ? (~shift_in + 1'b1) : shift_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_left_shifter (Pipelined)
// Function: Performs left barrel shift by shift_amt, registered between stages
// -----------------------------------------------------------------------------
module barrel_left_shifter #(
    parameter W = 24
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [W-1:0] data_in,
    input  wire [4:0]   shift_amt,
    output wire [W-1:0] data_out
);
    // Stage 0: shift by 1 if shift_amt[0] is set
    reg [W-1:0] stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage0 <= {W{1'b0}};
        else
            stage0 <= shift_amt[0] ? {data_in[W-2:0], 1'b0} : data_in;
    end

    // Stage 1: shift by 2 if shift_amt[1] is set
    reg [W-1:0] stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1 <= {W{1'b0}};
        else
            stage1 <= shift_amt[1] ? {stage0[W-3:0], 2'b00} : stage0;
    end

    // Stage 2: shift by 4 if shift_amt[2] is set
    reg [W-1:0] stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2 <= {W{1'b0}};
        else
            stage2 <= shift_amt[2] ? {stage1[W-5:0], 4'b0000} : stage1;
    end

    // Stage 3: shift by 8 if shift_amt[3] is set
    reg [W-1:0] stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3 <= {W{1'b0}};
        else
            stage3 <= shift_amt[3] ? {stage2[W-9:0], 8'b00000000} : stage2;
    end

    // Stage 4: shift by 16 if shift_amt[4] is set
    reg [W-1:0] stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage4 <= {W{1'b0}};
        else
            stage4 <= shift_amt[4] ? {stage3[W-17:0], 16'b0} : stage3;
    end

    assign data_out = stage4;
endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_right_shifter (Pipelined)
// Function: Performs right barrel shift by shift_amt, registered between stages
// -----------------------------------------------------------------------------
module barrel_right_shifter #(
    parameter W = 24
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [W-1:0] data_in,
    input  wire [4:0]   shift_amt,
    output wire [W-1:0] data_out
);
    // Stage 0: shift by 1 if shift_amt[0] is set
    reg [W-1:0] stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage0 <= {W{1'b0}};
        else
            stage0 <= shift_amt[0] ? {1'b0, data_in[W-1:1]} : data_in;
    end

    // Stage 1: shift by 2 if shift_amt[1] is set
    reg [W-1:0] stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1 <= {W{1'b0}};
        else
            stage1 <= shift_amt[1] ? {2'b00, stage0[W-1:2]} : stage0;
    end

    // Stage 2: shift by 4 if shift_amt[2] is set
    reg [W-1:0] stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2 <= {W{1'b0}};
        else
            stage2 <= shift_amt[2] ? {4'b0000, stage1[W-1:4]} : stage1;
    end

    // Stage 3: shift by 8 if shift_amt[3] is set
    reg [W-1:0] stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3 <= {W{1'b0}};
        else
            stage3 <= shift_amt[3] ? {8'b00000000, stage2[W-1:8]} : stage2;
    end

    // Stage 4: shift by 16 if shift_amt[4] is set
    reg [W-1:0] stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage4 <= {W{1'b0}};
        else
            stage4 <= shift_amt[4] ? {16'b0, stage3[W-1:16]} : stage3;
    end

    assign data_out = stage4;
endmodule