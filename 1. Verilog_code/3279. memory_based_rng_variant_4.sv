//SystemVerilog
module memory_based_rng #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire [3:0]         addr_seed,
    output wire [WIDTH-1:0]   random_val,
    output wire               random_val_valid
);

    // Memory declaration
    reg [WIDTH-1:0] mem_array [0:DEPTH-1];

    // ---------------------- Stage 1 ----------------------
    reg  [3:0] addr_ptr_stage1;
    reg [WIDTH-1:0] last_val_stage1;
    reg        valid_stage1;
    integer    i;

    // ---------------------- Stage 2 ----------------------
    reg  [3:0] addr_ptr_stage2;
    reg [WIDTH-1:0] last_val_stage2;
    reg [WIDTH-1:0] mem_val_stage2;
    reg        valid_stage2;

    // ---------------------- Stage 3 ----------------------
    reg  [3:0] addr_ptr_stage3;
    reg [WIDTH-1:0] last_val_stage3;
    reg [WIDTH-1:0] mem_val_stage3;
    reg        valid_stage3;

    // ---------------------- Stage 4 ----------------------
    reg [WIDTH-1:0] random_val_stage4;
    reg        valid_stage4;

    // ---------------------- Stage 1: Input Sampling and Initialization ----------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ptr_stage1   <= addr_seed;
            last_val_stage1   <= {WIDTH{1'b0}};
            valid_stage1      <= 1'b0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem_array[i] <= i * 7 + 11;
            end
        end else begin
            addr_ptr_stage1   <= addr_ptr_stage1;
            last_val_stage1   <= last_val_stage1;
            valid_stage1      <= 1'b1;
        end
    end

    // ---------------------- Stage 2: Calculate Memory Update Indices ----------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ptr_stage2   <= 4'd0;
            last_val_stage2   <= {WIDTH{1'b0}};
            mem_val_stage2    <= {WIDTH{1'b0}};
            valid_stage2      <= 1'b0;
        end else begin
            addr_ptr_stage2   <= addr_ptr_stage1;
            last_val_stage2   <= last_val_stage1;
            mem_val_stage2    <= mem_array[addr_ptr_stage1];
            valid_stage2      <= valid_stage1;
        end
    end

    // ---------------------- Stage 3: Memory Update & Address Calculation ----------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ptr_stage3   <= 4'd0;
            last_val_stage3   <= {WIDTH{1'b0}};
            mem_val_stage3    <= {WIDTH{1'b0}};
            valid_stage3      <= 1'b0;
        end else begin
            // Update memory value and write back
            mem_array[addr_ptr_stage2] <= mem_val_stage2 ^ (last_val_stage2 << 1);

            // Prepare for next stage
            addr_ptr_stage3   <= addr_ptr_stage2 + last_val_stage2[1:0] + 1'b1;
            last_val_stage3   <= mem_val_stage2;
            mem_val_stage3    <= mem_val_stage2 ^ (last_val_stage2 << 1);
            valid_stage3      <= valid_stage2;
        end
    end

    // ---------------------- Stage 4: Output Buffer ----------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            random_val_stage4 <= {WIDTH{1'b0}};
            valid_stage4      <= 1'b0;
        end else begin
            random_val_stage4 <= mem_array[addr_ptr_stage3];
            valid_stage4      <= valid_stage3;
        end
    end

    assign random_val      = random_val_stage4;
    assign random_val_valid = valid_stage4;

endmodule