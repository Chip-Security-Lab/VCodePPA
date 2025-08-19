//SystemVerilog
module FaultTolMux_Pipeline #(
    parameter DW = 8
) (
    input                  clk,
    input                  rst_n,
    input                  valid_in,
    input      [1:0]       sel_in,
    input      [3:0][DW-1:0] din_in,
    output reg             valid_out,
    output reg [DW-1:0]    dout,
    output reg             error_out
);

// Stage 1: Input Sampling
reg                   valid_stage1;
reg  [1:0]            sel_stage1;
reg  [3:0][DW-1:0]    din_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
        sel_stage1   <= 2'b0;
        din_stage1   <= {4{ {DW{1'b0}} }};
    end else begin
        valid_stage1 <= valid_in;
        sel_stage1   <= sel_in;
        din_stage1   <= din_in;
    end
end

// Stage 2: Primary/Backup Selection (Pipeline Register Inserted)
reg                   valid_stage2;
reg  [1:0]            sel_stage2;
reg  [3:0][DW-1:0]    din_stage2;
reg  [DW-1:0]         primary_stage2, backup_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2    <= 1'b0;
        sel_stage2      <= 2'b0;
        din_stage2      <= {4{ {DW{1'b0}} }};
        primary_stage2  <= {DW{1'b0}};
        backup_stage2   <= {DW{1'b0}};
    end else begin
        valid_stage2    <= valid_stage1;
        sel_stage2      <= sel_stage1;
        din_stage2      <= din_stage1;
        primary_stage2  <= din_stage1[sel_stage1];
        backup_stage2   <= din_stage1[~sel_stage1];
    end
end

// Stage 3: Parity Computation (Pipeline Register Inserted)
reg                   valid_stage3;
reg  [DW-1:0]         primary_stage3, backup_stage3;
reg                   parity_check_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage3         <= 1'b0;
        primary_stage3       <= {DW{1'b0}};
        backup_stage3        <= {DW{1'b0}};
        parity_check_stage3  <= 1'b0;
    end else begin
        valid_stage3         <= valid_stage2;
        primary_stage3       <= primary_stage2;
        backup_stage3        <= backup_stage2;
        parity_check_stage3  <= (^primary_stage2[7:4] == primary_stage2[3]);
    end
end

// Stage 4: Output Selection and Error Computation (Pipeline Register Inserted)
reg                   valid_stage4;
reg  [DW-1:0]         dout_stage4;
reg                   error_stage4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage4   <= 1'b0;
        dout_stage4    <= {DW{1'b0}};
        error_stage4   <= 1'b0;
    end else begin
        valid_stage4   <= valid_stage3;
        dout_stage4    <= (parity_check_stage3) ? primary_stage3 : backup_stage3;
        error_stage4   <= (primary_stage3 != backup_stage3);
    end
end

// Outputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out   <= 1'b0;
        dout        <= {DW{1'b0}};
        error_out   <= 1'b0;
    end else begin
        valid_out   <= valid_stage4;
        dout        <= dout_stage4;
        error_out   <= error_stage4;
    end
end

endmodule