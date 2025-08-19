//SystemVerilog
module fifo_based_shifter #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input                       clk,
    input                       rst_n,
    input  [WIDTH-1:0]          data_in,
    input                       push,
    input                       pop,
    input  [2:0]                shift_amount,
    output [WIDTH-1:0]          data_out
);

    // Stage 1: Input Registration
    reg  [WIDTH-1:0]            stage1_data_in;
    reg                         stage1_push;

    // Stage 2: FIFO Write
    reg  [$clog2(DEPTH)-1:0]    stage2_write_pointer;
    reg  [$clog2(DEPTH)-1:0]    stage2_read_pointer;
    reg                         stage2_push;
    reg  [WIDTH-1:0]            stage2_data_in;

    // FIFO Memory
    reg  [WIDTH-1:0]            fifo_mem [0:DEPTH-1];

    // Stage 3: FIFO Update and Read Pointer
    reg  [$clog2(DEPTH)-1:0]    stage3_write_pointer;
    reg  [$clog2(DEPTH)-1:0]    stage3_read_pointer;
    reg                         stage3_pop;

    // Stage 4: Shifted Address Calculation
    reg  [$clog2(DEPTH)-1:0]    stage4_shifted_addr;
    reg  [$clog2(DEPTH)-1:0]    stage4_read_pointer;
    reg  [2:0]                  stage4_shift_amount;

    // Stage 5: Data Output Registration
    reg  [WIDTH-1:0]            stage5_data_out;

    // Output assignment
    assign data_out = stage5_data_out;

    // Stage 1: Register input data and push signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data_in <= {WIDTH{1'b0}};
            stage1_push    <= 1'b0;
        end else begin
            stage1_data_in <= data_in;
            stage1_push    <= push;
        end
    end

    // Stage 2: Register data for FIFO write and pointers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_write_pointer <= {($clog2(DEPTH)){1'b0}};
            stage2_read_pointer  <= {($clog2(DEPTH)){1'b0}};
            stage2_push          <= 1'b0;
            stage2_data_in       <= {WIDTH{1'b0}};
        end else begin
            stage2_write_pointer <= stage3_write_pointer;
            stage2_read_pointer  <= stage3_read_pointer;
            stage2_push          <= stage1_push;
            stage2_data_in       <= stage1_data_in;
        end
    end

    // Stage 3: FIFO memory update, pointer update, and registering pop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_write_pointer <= {($clog2(DEPTH)){1'b0}};
            stage3_read_pointer  <= {($clog2(DEPTH)){1'b0}};
            stage3_pop           <= 1'b0;
        end else begin
            // FIFO write
            if (stage2_push) begin
                fifo_mem[stage2_write_pointer] <= stage2_data_in;
                stage3_write_pointer <= stage2_write_pointer + 1'b1;
            end else begin
                stage3_write_pointer <= stage2_write_pointer;
            end

            // FIFO read pointer update
            if (pop) begin
                stage3_read_pointer <= stage2_read_pointer + 1'b1;
            end else begin
                stage3_read_pointer <= stage2_read_pointer;
            end

            stage3_pop <= pop;
        end
    end

    // Stage 4: Calculate shifted address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_read_pointer  <= {($clog2(DEPTH)){1'b0}};
            stage4_shift_amount  <= 3'b000;
            stage4_shifted_addr  <= {($clog2(DEPTH)){1'b0}};
        end else begin
            stage4_read_pointer  <= stage3_read_pointer;
            stage4_shift_amount  <= shift_amount;
            stage4_shifted_addr  <= (stage3_read_pointer + shift_amount) % DEPTH;
        end
    end

    // Stage 5: Register output data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_data_out <= {WIDTH{1'b0}};
        end else begin
            stage5_data_out <= fifo_mem[stage4_shifted_addr];
        end
    end

endmodule