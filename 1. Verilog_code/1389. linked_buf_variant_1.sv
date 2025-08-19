//SystemVerilog
module linked_buf #(parameter DW=8, SIZE=8) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // Define memory structure with arrays
    reg [DW-1:0] mem_data [0:SIZE-1];
    reg [2:0] mem_next [0:SIZE-1];
    reg [2:0] head, tail, free_ptr;
    integer i;
    
    // Pipeline registers for critical path optimization
    reg [2:0] head_pipe, tail_pipe, free_ptr_pipe;
    reg [2:0] next_head, next_free_ptr;
    reg [DW-1:0] rd_data_pipe;
    reg is_head_eq_tail_pipe;
    
    // First pipeline stage - calculate next values
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            head_pipe <= 0;
            tail_pipe <= 0;
            free_ptr_pipe <= 1;
            is_head_eq_tail_pipe <= 1'b0;
            rd_data_pipe <= {DW{1'b0}};
            next_head <= 0;
            next_free_ptr <= 0;
        end
        else begin
            // Pipeline current state values
            head_pipe <= head;
            tail_pipe <= tail;
            free_ptr_pipe <= free_ptr;
            
            // Pre-compute read data and condition for critical path reduction
            if(rd_en && head != 0) begin
                rd_data_pipe <= mem_data[head];
                next_head <= mem_next[head];
                next_free_ptr <= head;
                is_head_eq_tail_pipe <= (head == tail);
            end
        end
    end
    
    // Second pipeline stage - update state
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            head <= 0;
            tail <= 0;
            free_ptr <= 1;
            dout <= {DW{1'b0}};
            
            for(i=0;i<SIZE;i=i+1) begin
                if(i < SIZE-1)
                    mem_next[i] <= i+1;
                else
                    mem_next[i] <= 0;
            end
        end
        else begin
            // Write operation logic
            if(wr_en && free_ptr != 0) begin
                mem_data[free_ptr] <= din;
                tail <= free_ptr;
                free_ptr <= mem_next[free_ptr];
            end
            
            // Read operation with pipelined values
            if(rd_en && head_pipe != 0) begin
                dout <= rd_data_pipe;
                mem_next[head_pipe] <= free_ptr_pipe;
                free_ptr <= next_free_ptr;
                head <= is_head_eq_tail_pipe ? 0 : next_head;
            end
        end
    end
endmodule