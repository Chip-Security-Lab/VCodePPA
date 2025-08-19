//SystemVerilog
module shift_preset_pipeline #(parameter W=8) (
    input                  clk,
    input                  rst_n,
    input                  preset,
    input  [W-1:0]         preset_val,
    input                  in_valid,
    output reg [W-1:0]     dout,
    output reg             out_valid
);

// Stage 1: Latch inputs and control, now also includes registers for output data path
reg                       preset_stage1;
reg  [W-1:0]              preset_val_stage1;
reg  [W-1:0]              dout_stage1;
reg                       valid_stage1;

// Registers for retimed output data path (formerly dout_stage2, valid_stage2, dout/out_valid)
reg  [W-1:0]              dout_stage2_reg;
reg                       valid_stage2_reg;

// Internal signals for conditional sum subtraction
wire [W-1:0]              shifted_data;
wire [W-1:0]              one_vector;
wire [W-1:0]              sum_stage1;
wire                      carry_in;
wire [W-1:0]              carry_generate;
wire [W-1:0]              carry_propagate;
wire [W:0]                carry;

// Conditional Sum Subtraction signals
assign one_vector = { {W-1{1'b0}}, 1'b1 };
assign carry_in   = 1'b1; // For subtraction, add 1 after bitwise inversion

// Generate block for conditional sum subtraction (dout_stage1 - 1)
genvar i;
generate
    assign carry[0] = carry_in;
    for (i = 0; i < W; i = i + 1) begin : COND_SUM_SUB
        assign carry_generate[i] = ~dout_stage1[i] & one_vector[i];
        assign carry_propagate[i] = ~(dout_stage1[i] ^ one_vector[i]);
        assign sum_stage1[i] = dout_stage1[i] ^ one_vector[i] ^ carry[i];
        assign carry[i+1] = (dout_stage1[i] & one_vector[i]) | ((dout_stage1[i] ^ one_vector[i]) & carry[i]);
    end
endgenerate

assign shifted_data = {sum_stage1[W-2:0], 1'b1};

// Stage 1: Input register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        preset_stage1      <= 1'b0;
        preset_val_stage1  <= {W{1'b0}};
        dout_stage1        <= {W{1'b0}};
        valid_stage1       <= 1'b0;
    end else begin
        if (in_valid) begin
            preset_stage1     <= preset;
            preset_val_stage1 <= preset_val;
            dout_stage1       <= dout;
            valid_stage1      <= 1'b1;
        end else begin
            valid_stage1      <= 1'b0;
        end
    end
end

// Stage 2: Shift or preset logic (combinational), output registers retimed to this stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage2_reg   <= {W{1'b0}};
        valid_stage2_reg  <= 1'b0;
    end else begin
        if (valid_stage1) begin
            if (preset_stage1)
                dout_stage2_reg <= preset_val_stage1;
            else
                dout_stage2_reg <= shifted_data;
            valid_stage2_reg <= 1'b1;
        end else begin
            valid_stage2_reg <= 1'b0;
        end
    end
end

// Stage 3: Output logic (removed register, direct assignment from stage 2 registers)
always @(*) begin
    dout      = dout_stage2_reg;
    out_valid = valid_stage2_reg;
end

endmodule