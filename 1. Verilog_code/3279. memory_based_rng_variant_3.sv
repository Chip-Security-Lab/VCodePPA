//SystemVerilog
module memory_based_rng #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire       [3:0]  addr_seed,
    output wire [WIDTH-1:0]  random_val,
    output wire              valid_out
);

    // Memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Stage 1: Address Calculation
    reg [3:0]  address_pointer_stage1;
    reg [WIDTH-1:0] previous_value_stage1;
    reg        valid_stage1;

    // Stage 2: Read/Update Memory
    reg [3:0]  address_pointer_stage2;
    reg [WIDTH-1:0] previous_value_stage2;
    reg [WIDTH-1:0] mem_read_stage2;
    reg        valid_stage2;

    // Stage 3: Write-back and Next Address Calculation
    reg [3:0]  address_pointer_stage3;
    reg [WIDTH-1:0] previous_value_stage3;
    reg [WIDTH-1:0] mem_writeback_stage3;
    reg        valid_stage3;

    // Flush/Reset logic
    integer idx;
    reg rst_done;

    // Stage 1: Address and previous_value latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_pointer_stage1    <= 4'd0;
            previous_value_stage1     <= {WIDTH{1'b0}};
            valid_stage1              <= 1'b0;
        end else if (!rst_done) begin
            address_pointer_stage1    <= addr_seed;
            previous_value_stage1     <= {WIDTH{1'b0}};
            valid_stage1              <= 1'b1;
        end else begin
            address_pointer_stage1    <= address_pointer_stage3;
            previous_value_stage1     <= previous_value_stage3;
            valid_stage1              <= valid_stage3;
        end
    end

    // Stage 2: Memory read, prepare values for operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_pointer_stage2    <= 4'd0;
            previous_value_stage2     <= {WIDTH{1'b0}};
            mem_read_stage2           <= {WIDTH{1'b0}};
            valid_stage2              <= 1'b0;
        end else if (!rst_done) begin
            address_pointer_stage2    <= 4'd0;
            previous_value_stage2     <= {WIDTH{1'b0}};
            mem_read_stage2           <= {WIDTH{1'b0}};
            valid_stage2              <= 1'b0;
        end else begin
            address_pointer_stage2    <= address_pointer_stage1;
            previous_value_stage2     <= previous_value_stage1;
            mem_read_stage2           <= mem[address_pointer_stage1];
            valid_stage2              <= valid_stage1;
        end
    end

    // Stage 3: Memory update, calculate next address and previous_value
    wire [WIDTH-1:0] mem_xor_stage3 = mem_read_stage2 ^ (previous_value_stage2 << 1);
    wire [3:0] next_address_stage3 = (address_pointer_stage2 + previous_value_stage2[1:0] + 4'd1) & 4'hF;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_pointer_stage3    <= 4'd0;
            previous_value_stage3     <= {WIDTH{1'b0}};
            mem_writeback_stage3      <= {WIDTH{1'b0}};
            valid_stage3              <= 1'b0;
        end else if (!rst_done) begin
            address_pointer_stage3    <= 4'd0;
            previous_value_stage3     <= {WIDTH{1'b0}};
            mem_writeback_stage3      <= {WIDTH{1'b0}};
            valid_stage3              <= 1'b0;
        end else begin
            address_pointer_stage3    <= next_address_stage3;
            previous_value_stage3     <= mem_read_stage2;
            mem_writeback_stage3      <= mem_xor_stage3;
            valid_stage3              <= valid_stage2;
        end
    end

    // Memory write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_done <= 1'b0;
        end else if (!rst_done) begin
            // Memory initialization
            for (idx = 0; idx < DEPTH; idx = idx + 1)
                mem[idx] <= idx * 7 + 8'd11;
            rst_done <= 1'b1;
        end else if (valid_stage2) begin
            mem[address_pointer_stage2] <= mem_xor_stage3;
        end
    end

    // Output assignment: output is the memory at the writeback address
    assign random_val = mem[mem_writeback_stage3[3:0]];
    assign valid_out  = valid_stage3;

endmodule