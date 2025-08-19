//SystemVerilog
module barrel_shifter #(parameter N=8) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [N-1:0]         in,
    input  wire [$clog2(N)-1:0] shift,
    output wire [N-1:0]         out
);

// Stage 1: Register input and shift
reg [N-1:0]         data_reg_stage1;
reg [$clog2(N)-1:0] shift_reg_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg_stage1  <= {N{1'b0}};
        shift_reg_stage1 <= {$clog2(N){1'b0}};
    end else begin
        data_reg_stage1  <= in;
        shift_reg_stage1 <= shift;
    end
end

// Stage 2: Pipeline partial shift computations
reg [N-1:0] left_shifted_stage2;
reg [N-1:0] wrap_mask_stage2;
reg [$clog2(N)-1:0] shift_reg_stage2;
reg [N-1:0] data_reg_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        left_shifted_stage2 <= {N{1'b0}};
        wrap_mask_stage2    <= {N{1'b0}};
        shift_reg_stage2    <= {$clog2(N){1'b0}};
        data_reg_stage2     <= {N{1'b0}};
    end else begin
        left_shifted_stage2 <= data_reg_stage1 << shift_reg_stage1;
        wrap_mask_stage2    <= (shift_reg_stage1 == 0) ? {N{1'b0}} : (data_reg_stage1 >> (N - shift_reg_stage1));
        shift_reg_stage2    <= shift_reg_stage1;
        data_reg_stage2     <= data_reg_stage1;
    end
end

// Stage 3: Pipeline shift==0 decision
reg [N-1:0] shifted_or_mask_stage3;
reg [N-1:0] data_reg_stage3;
reg [$clog2(N)-1:0] shift_reg_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shifted_or_mask_stage3 <= {N{1'b0}};
        data_reg_stage3        <= {N{1'b0}};
        shift_reg_stage3       <= {$clog2(N){1'b0}};
    end else begin
        shifted_or_mask_stage3 <= left_shifted_stage2 | wrap_mask_stage2;
        data_reg_stage3        <= data_reg_stage2;
        shift_reg_stage3       <= shift_reg_stage2;
    end
end

// Stage 4: Final output select
reg [N-1:0] out_reg_stage4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_reg_stage4 <= {N{1'b0}};
    end else begin
        out_reg_stage4 <= (shift_reg_stage3 == 0) ? data_reg_stage3 : shifted_or_mask_stage3;
    end
end

assign out = out_reg_stage4;

endmodule