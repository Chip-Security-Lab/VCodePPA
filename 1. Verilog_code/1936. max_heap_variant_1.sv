//SystemVerilog
module max_heap_pipelined #(parameter DW=8, HEAP_SIZE=16) (
    input                  clk,
    input                  rst_n,
    input                  insert,
    input  [DW-1:0]        data_in,
    output reg [DW-1:0]    data_out,
    output                 valid_out
);

    // HEAP storage and index
    reg [DW-1:0] heap_mem [0:HEAP_SIZE-1];
    reg [4:0]    heap_index_stage1, heap_index_stage2, heap_index_stage3;
    reg [DW-1:0] data_in_stage1, data_in_stage2, data_in_stage3;
    reg          insert_stage1, insert_stage2, insert_stage3;
    reg          valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg [DW-1:0] data_out_stage3, data_out_stage4;
    reg [4:0]    last_index_stage1, last_index_stage2, last_index_stage3;

    // Initialization
    integer i;
    initial begin
        for(i=0; i<HEAP_SIZE; i=i+1)
            heap_mem[i] = {DW{1'b0}};
    end

    // Stage 1: Register inputs and heap_index
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage1    <= {DW{1'b0}};
            insert_stage1     <= 1'b0;
            heap_index_stage1 <= 5'b0;
            last_index_stage1 <= 5'b0;
            valid_stage1      <= 1'b0;
        end else begin
            data_in_stage1    <= data_in;
            insert_stage1     <= insert;
            heap_index_stage1 <= heap_index_stage3; // feedback from stage 3
            last_index_stage1 <= heap_index_stage3;
            valid_stage1      <= 1'b1;
        end
    end

    // Stage 2: Prepare heap operations
    reg [DW-1:0] heap_write_data_stage2;
    reg [4:0]    heap_write_addr_stage2;
    reg [DW-1:0] heap_read_data_stage2;
    reg [DW-1:0] heap_swap_data_stage2;
    reg [4:0]    heap_swap_addr_stage2;
    reg [4:0]    next_heap_index_stage2;
    reg [DW-1:0] data_out_candidate_stage2;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_stage2    <= {DW{1'b0}};
            insert_stage2     <= 1'b0;
            heap_index_stage2 <= 5'b0;
            last_index_stage2 <= 5'b0;
            valid_stage2      <= 1'b0;
        end else begin
            data_in_stage2    <= data_in_stage1;
            insert_stage2     <= insert_stage1;
            heap_index_stage2 <= heap_index_stage1;
            last_index_stage2 <= last_index_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3: Perform heap operation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            insert_stage3     <= 1'b0;
            heap_index_stage3 <= 5'b0;
            data_out_stage3   <= {DW{1'b0}};
            last_index_stage3 <= 5'b0;
            valid_stage3      <= 1'b0;
        end else begin
            insert_stage3     <= insert_stage2;
            heap_index_stage3 <= (insert_stage2) ? (heap_index_stage2 + 1'b1) :
                                (heap_index_stage2 > 0) ? (heap_index_stage2 - 1'b1) :
                                heap_index_stage2;
            last_index_stage3 <= heap_index_stage2;
            valid_stage3      <= valid_stage2;
            if(insert_stage2) begin
                heap_mem[heap_index_stage2] <= data_in_stage2;
                data_out_stage3 <= data_out_stage3; // No output on insert
            end else if(heap_index_stage2 > 0) begin
                data_out_stage3 <= heap_mem[0];
                heap_mem[0] <= heap_mem[heap_index_stage2-1'b1];
            end
        end
    end

    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out_stage4 <= {DW{1'b0}};
            valid_stage4    <= 1'b0;
        end else begin
            data_out_stage4 <= data_out_stage3;
            valid_stage4    <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= {DW{1'b0}};
        end else begin
            data_out <= data_out_stage4;
        end
    end

    assign valid_out = valid_stage4;

endmodule