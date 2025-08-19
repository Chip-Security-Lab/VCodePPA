//SystemVerilog
module shift_multiphase_pipeline #(parameter WIDTH=8) (
    input  wire                clk0,
    input  wire                clk1,
    input  wire                rst_n,
    input  wire                din_valid,
    input  wire [WIDTH-1:0]    din,
    output reg                 dout_valid,
    output reg  [WIDTH-1:0]    dout
);

// Stage 1: Input Register (clk0 domain)
reg [WIDTH-1:0] din_input_reg;
reg             din_valid_reg;

always @(posedge clk0 or negedge rst_n) begin
    if (!rst_n) begin
        din_input_reg  <= {WIDTH{1'b0}};
    end else begin
        din_input_reg  <= din;
    end
end

always @(posedge clk0 or negedge rst_n) begin
    if (!rst_n) begin
        din_valid_reg <= 1'b0;
    end else begin
        din_valid_reg <= din_valid;
    end
end

// Stage 2: CDC Sync Registers (clk1 domain)
reg [WIDTH-1:0] din_sync_stage1;
reg [WIDTH-1:0] din_sync_stage2;
reg             valid_sync_stage1;
reg             valid_sync_stage2;

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        din_sync_stage1 <= {WIDTH{1'b0}};
    end else begin
        din_sync_stage1 <= din_input_reg;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        din_sync_stage2 <= {WIDTH{1'b0}};
    end else begin
        din_sync_stage2 <= din_sync_stage1;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        valid_sync_stage1 <= 1'b0;
    end else begin
        valid_sync_stage1 <= din_valid_reg;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        valid_sync_stage2 <= 1'b0;
    end else begin
        valid_sync_stage2 <= valid_sync_stage1;
    end
end

// Stage 3: Data Register after CDC sync (clk1 domain)
reg [WIDTH-1:0] din_cdc_reg;
reg             valid_cdc_reg;

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        din_cdc_reg <= {WIDTH{1'b0}};
    end else begin
        din_cdc_reg <= din_sync_stage2;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        valid_cdc_reg <= 1'b0;
    end else begin
        valid_cdc_reg <= valid_sync_stage2;
    end
end

// Stage 4: Shift Operation (clk1 domain)
reg [WIDTH-1:0] shift_reg;
reg             shift_valid_reg;

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= {WIDTH{1'b0}};
    end else begin
        shift_reg <= din_cdc_reg << 2;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        shift_valid_reg <= 1'b0;
    end else begin
        shift_valid_reg <= valid_cdc_reg;
    end
end

// Stage 5: Output Register (clk1 domain)
always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {WIDTH{1'b0}};
    end else begin
        dout <= shift_reg;
    end
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
        dout_valid <= 1'b0;
    end else begin
        dout_valid <= shift_valid_reg;
    end
end

endmodule