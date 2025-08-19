//SystemVerilog
// SystemVerilog IEEE 1364-2005
module linked_buf #(parameter DW=8, SIZE=8) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg ready_in,
    output reg valid_out
);
    // Define memory structure with arrays
    reg [DW-1:0] mem_data [0:SIZE-1];
    reg [2:0] mem_next [0:SIZE-1];
    reg [2:0] head, tail, free_ptr;
    
    // Stage 1: Input registration and command decoding
    reg wr_en_stage1, rd_en_stage1;
    reg [DW-1:0] din_stage1;
    reg [2:0] next_free_ptr_stage1;
    reg [2:0] next_head_stage1;
    reg head_eq_tail_stage1;
    reg valid_stage1;
    
    // Stage 2: Memory access preparation
    reg wr_en_stage2, rd_en_stage2;
    reg [DW-1:0] din_stage2;
    reg [2:0] free_ptr_stage2, head_stage2, tail_stage2;
    reg [2:0] next_free_ptr_stage2;
    reg [2:0] next_head_stage2;
    reg head_eq_tail_stage2;
    reg valid_stage2;
    
    // Stage 3: Memory access execution
    reg wr_en_stage3, rd_en_stage3;
    reg [DW-1:0] din_stage3;
    reg [DW-1:0] read_data_stage3;
    reg valid_stage3;
    
    // Bookkeeping for pipeline control
    wire can_accept = (free_ptr != 0);
    wire can_provide = (head != 0);
    
    integer i;
    
    // Stage 1: Input registration and command decoding
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_en_stage1 <= 1'b0;
            rd_en_stage1 <= 1'b0;
            din_stage1 <= {DW{1'b0}};
            next_free_ptr_stage1 <= 3'b0;
            next_head_stage1 <= 3'b0;
            head_eq_tail_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
            ready_in <= 1'b0;
        end
        else begin
            wr_en_stage1 <= wr_en && can_accept;
            rd_en_stage1 <= rd_en && can_provide;
            din_stage1 <= din;
            next_free_ptr_stage1 <= mem_next[free_ptr];
            next_head_stage1 <= mem_next[head];
            head_eq_tail_stage1 <= (head == tail);
            valid_stage1 <= (wr_en && can_accept) || (rd_en && can_provide);
            ready_in <= can_accept;
        end
    end
    
    // Stage 2: Memory access preparation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_en_stage2 <= 1'b0;
            rd_en_stage2 <= 1'b0;
            din_stage2 <= {DW{1'b0}};
            free_ptr_stage2 <= 3'b0;
            head_stage2 <= 3'b0;
            tail_stage2 <= 3'b0;
            next_free_ptr_stage2 <= 3'b0;
            next_head_stage2 <= 3'b0;
            head_eq_tail_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            wr_en_stage2 <= wr_en_stage1;
            rd_en_stage2 <= rd_en_stage1;
            din_stage2 <= din_stage1;
            free_ptr_stage2 <= free_ptr;
            head_stage2 <= head;
            tail_stage2 <= tail;
            next_free_ptr_stage2 <= next_free_ptr_stage1;
            next_head_stage2 <= next_head_stage1;
            head_eq_tail_stage2 <= head_eq_tail_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Memory access execution
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_en_stage3 <= 1'b0;
            rd_en_stage3 <= 1'b0;
            din_stage3 <= {DW{1'b0}};
            read_data_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            wr_en_stage3 <= wr_en_stage2;
            rd_en_stage3 <= rd_en_stage2;
            din_stage3 <= din_stage2;
            if(rd_en_stage2) begin
                read_data_stage3 <= mem_data[head_stage2];
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final stage: State update and output generation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            head <= 0;
            tail <= 0;
            free_ptr <= 1;
            dout <= {DW{1'b0}};
            valid_out <= 1'b0;
            
            for(i=0;i<SIZE;i=i+1) begin
                if(i < SIZE-1)
                    mem_next[i] <= i+1;
                else
                    mem_next[i] <= 0;
            end
        end
        else begin
            valid_out <= rd_en_stage3;
            
            if(wr_en_stage3) begin
                mem_data[free_ptr_stage2] <= din_stage3;
                tail <= free_ptr_stage2;
                free_ptr <= next_free_ptr_stage2;
            end
            
            if(rd_en_stage3) begin
                dout <= read_data_stage3;
                mem_next[head_stage2] <= free_ptr_stage2;
                free_ptr <= head_stage2;
                head <= head_eq_tail_stage2 ? 0 : next_head_stage2;
            end
        end
    end
endmodule