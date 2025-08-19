//SystemVerilog
module circular_queue_pipeline #(
    parameter DW = 8,
    parameter DEPTH = 16
)(
    input                   clk,
    input                   rst_n,
    input                   en,
    input                   flush,
    input  [DW-1:0]         data_in,
    output [DW-1:0]         data_out,
    output                  full,
    output                  empty,
    output                  valid_out
);
    // Memory array
    reg [DW-1:0] mem [0:DEPTH-1];

    // Pointer and count registers per stage
    reg [$clog2(DEPTH)-1:0] w_ptr_stage1, w_ptr_stage2;
    reg [$clog2(DEPTH)-1:0] r_ptr_stage1, r_ptr_stage2;
    reg [4:0]               count_stage1, count_stage2;

    // Data and control registers per stage
    reg [DW-1:0]            data_in_stage1, data_in_stage2;
    reg                     write_en_stage1, write_en_stage2;
    reg                     read_en_stage1, read_en_stage2;

    // Valid signals for each pipeline stage
    reg                     valid_stage1, valid_stage2, valid_stage3;

    // Output registers
    reg [DW-1:0]            data_out_stage3;
    reg [$clog2(DEPTH)-1:0] r_ptr_stage3;
    reg [4:0]               count_stage3;
    reg                     full_stage3, empty_stage3;

    // Lookup tables for 5-bit subtraction: LUT_sub[MINUEND][SUBTRAHEND]
    reg [4:0] lut_sub [0:31][0:31];

    // Lookup tables for 5-bit addition: LUT_add[ADDEND][AUGEND]
    reg [4:0] lut_add [0:31][0:31];

    // Lookup tables for pointer increment (mod DEPTH)
    reg [$clog2(DEPTH)-1:0] lut_ptr_inc [0:DEPTH-1];

    integer i, j;

    // Synchronous LUT initialization
    initial begin
        // 5-bit subtraction LUT
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                lut_sub[i][j] = i - j;
                lut_add[i][j] = i + j;
            end
        end
        // Pointer increment LUT (mod DEPTH)
        for (i = 0; i < DEPTH; i = i + 1) begin
            lut_ptr_inc[i] = (i + 1) % DEPTH;
        end
    end

    // Assign outputs
    assign data_out = data_out_stage3;
    assign full     = full_stage3;
    assign empty    = empty_stage3;
    assign valid_out = valid_stage3;

    // Stage 1: Decode input, compute next pointers and count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            data_in_stage1  <= {DW{1'b0}};
            write_en_stage1 <= 1'b0;
            read_en_stage1  <= 1'b0;
            w_ptr_stage1    <= {($clog2(DEPTH)){1'b0}};
            r_ptr_stage1    <= {($clog2(DEPTH)){1'b0}};
            count_stage1    <= 5'd0;
            valid_stage1    <= 1'b0;
        end else if (en) begin
            data_in_stage1  <= data_in;
            write_en_stage1 <= 1'b1;
            read_en_stage1  <= 1'b1;
            w_ptr_stage1    <= w_ptr_stage2;
            r_ptr_stage1    <= r_ptr_stage2;
            count_stage1    <= count_stage2;
            valid_stage1    <= 1'b1;
        end else begin
            write_en_stage1 <= 1'b0;
            read_en_stage1  <= 1'b0;
            valid_stage1    <= 1'b0;
        end
    end

    // Stage 2: Write/Read Memory, update pointers and count
    reg [4:0] count_stage2_next_add;
    reg [4:0] count_stage2_next_sub;
    reg [4:0] count_stage2_next;

    always @(*) begin
        // LUT-based count increment and decrement
        count_stage2_next_add = lut_add[count_stage1][5'd1];
        count_stage2_next_sub = lut_sub[count_stage2_next_add][5'd1];
        // Default: keep value
        count_stage2_next = count_stage1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            w_ptr_stage2    <= {($clog2(DEPTH)){1'b0}};
            r_ptr_stage2    <= {($clog2(DEPTH)){1'b0}};
            count_stage2    <= 5'd0;
            data_in_stage2  <= {DW{1'b0}};
            write_en_stage2 <= 1'b0;
            read_en_stage2  <= 1'b0;
            valid_stage2    <= 1'b0;
        end else if (valid_stage1) begin
            // Write logic
            if ((count_stage1 < DEPTH) && write_en_stage1) begin
                mem[w_ptr_stage1] <= data_in_stage1;
                w_ptr_stage2 <= lut_ptr_inc[w_ptr_stage1];
                count_stage2 <= count_stage2_next_add;
            end else begin
                w_ptr_stage2 <= w_ptr_stage1;
                count_stage2 <= count_stage1;
            end

            // Read logic
            if ((count_stage1 > 0) && read_en_stage1) begin
                data_in_stage2  <= mem[r_ptr_stage1];
                r_ptr_stage2    <= lut_ptr_inc[r_ptr_stage1];
                count_stage2    <= lut_sub[count_stage2][5'd1];
            end else begin
                data_in_stage2  <= {DW{1'b0}};
                r_ptr_stage2    <= r_ptr_stage1;
            end

            write_en_stage2 <= write_en_stage1 & (count_stage1 < DEPTH);
            read_en_stage2  <= read_en_stage1 & (count_stage1 > 0);
            valid_stage2    <= 1'b1;
        end else begin
            write_en_stage2 <= 1'b0;
            read_en_stage2  <= 1'b0;
            valid_stage2    <= 1'b0;
        end
    end

    // Stage 3: Output stage, update output register, valid and status
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            data_out_stage3 <= {DW{1'b0}};
            r_ptr_stage3    <= {($clog2(DEPTH)){1'b0}};
            count_stage3    <= 5'd0;
            full_stage3     <= 1'b0;
            empty_stage3    <= 1'b1;
            valid_stage3    <= 1'b0;
        end else if (valid_stage2) begin
            if (read_en_stage2) begin
                data_out_stage3 <= data_in_stage2;
            end else begin
                data_out_stage3 <= data_out_stage3;
            end
            r_ptr_stage3  <= r_ptr_stage2;
            count_stage3  <= count_stage2;
            full_stage3   <= (count_stage2 == DEPTH);
            empty_stage3  <= (count_stage2 == 0);
            valid_stage3  <= 1'b1;
        end else begin
            valid_stage3  <= 1'b0;
        end
    end

endmodule