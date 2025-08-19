//SystemVerilog
module multi_domain_reset_controller(
    input  wire        clk,
    input  wire        global_rst_n,
    input  wire        por_n,
    input  wire        ext_n,
    input  wire        wdt_n,
    input  wire        sw_n,
    output reg         core_rst_n,
    output reg         periph_rst_n,
    output reg         mem_rst_n
);

// Stage 1: Compute any_reset_internal (combinational)
wire any_reset_stage1 = ~por_n | ~ext_n | ~wdt_n | ~sw_n;

// Stage 2: Pipeline buffer for any_reset
reg any_reset_stage2;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        any_reset_stage2 <= 1'b0;
    else
        any_reset_stage2 <= any_reset_stage1;
end

// Stage 3: Pipeline buffer for any_reset
reg any_reset_stage3;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        any_reset_stage3 <= 1'b0;
    else
        any_reset_stage3 <= any_reset_stage2;
end

// Stage 4: Pipeline buffer for any_reset
reg any_reset_stage4;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        any_reset_stage4 <= 1'b0;
    else
        any_reset_stage4 <= any_reset_stage3;
end

wire any_reset_piped = any_reset_stage4;

// Stage 1: reset_count update
reg [1:0] reset_count_stage1;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        reset_count_stage1 <= 2'b00;
    else if (any_reset_piped)
        reset_count_stage1 <= 2'b00;
    else if (reset_count_stage1 != 2'b11)
        reset_count_stage1 <= reset_count_stage1 + 1'b1;
    else
        reset_count_stage1 <= 2'b11;
end

// Stage 2: Pipeline reset_count
reg [1:0] reset_count_stage2;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        reset_count_stage2 <= 2'b00;
    else
        reset_count_stage2 <= reset_count_stage1;
end

// Stage 3: Pipeline reset_count
reg [1:0] reset_count_stage3;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        reset_count_stage3 <= 2'b00;
    else
        reset_count_stage3 <= reset_count_stage2;
end

// Stage 4: Pipeline reset_count
reg [1:0] reset_count_stage4;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        reset_count_stage4 <= 2'b00;
    else
        reset_count_stage4 <= reset_count_stage3;
end

wire [1:0] reset_count_piped = reset_count_stage4;

// Stage 1: Core reset comparator
reg core_rst_cmp_stage1;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        core_rst_cmp_stage1 <= 1'b0;
    else
        core_rst_cmp_stage1 <= (reset_count_piped >= 2'b01);
end

// Stage 2: Pipeline core_rst_cmp
reg core_rst_cmp_stage2;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        core_rst_cmp_stage2 <= 1'b0;
    else
        core_rst_cmp_stage2 <= core_rst_cmp_stage1;
end

// Stage 1: Periph reset comparator
reg periph_rst_cmp_stage1;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        periph_rst_cmp_stage1 <= 1'b0;
    else
        periph_rst_cmp_stage1 <= (reset_count_piped >= 2'b10);
end

// Stage 2: Pipeline periph_rst_cmp
reg periph_rst_cmp_stage2;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        periph_rst_cmp_stage2 <= 1'b0;
    else
        periph_rst_cmp_stage2 <= periph_rst_cmp_stage1;
end

// Stage 1: Mem reset comparator
reg mem_rst_cmp_stage1;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        mem_rst_cmp_stage1 <= 1'b0;
    else
        mem_rst_cmp_stage1 <= (reset_count_piped == 2'b11);
end

// Stage 2: Pipeline mem_rst_cmp
reg mem_rst_cmp_stage2;
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n)
        mem_rst_cmp_stage2 <= 1'b0;
    else
        mem_rst_cmp_stage2 <= mem_rst_cmp_stage1;
end

// Stage 5: Output registers (final pipeline stage)
always @(posedge clk or negedge global_rst_n) begin
    if (!global_rst_n) begin
        core_rst_n   <= 1'b0;
        periph_rst_n <= 1'b0;
        mem_rst_n    <= 1'b0;
    end else if (any_reset_piped) begin
        core_rst_n   <= 1'b0;
        periph_rst_n <= 1'b0;
        mem_rst_n    <= 1'b0;
    end else begin
        core_rst_n   <= core_rst_cmp_stage2;
        periph_rst_n <= periph_rst_cmp_stage2;
        mem_rst_n    <= mem_rst_cmp_stage2;
    end
end

endmodule