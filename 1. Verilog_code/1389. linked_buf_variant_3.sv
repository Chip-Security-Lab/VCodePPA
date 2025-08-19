//SystemVerilog
//IEEE 1364-2005 Verilog
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
    
    // Buffer registers for high fan-out signals
    reg [DW-1:0] mem_data_buf1 [0:SIZE-1];
    reg [DW-1:0] mem_data_buf2 [0:SIZE-1];
    reg [2:0] mem_next_buf1 [0:SIZE-1];
    reg [2:0] mem_next_buf2 [0:SIZE-1];
    reg [2:0] head_buf1, head_buf2;
    reg [2:0] free_ptr_buf1, free_ptr_buf2;
    reg read_last_element_buf;
    
    // Optimized control signals
    wire empty;
    wire has_free_space;
    wire do_read;
    wire do_write;
    wire read_last_element;
    wire do_read_and_write;
    
    // Efficient condition checking
    assign empty = (head == 0);
    assign has_free_space = (free_ptr != 0);
    assign do_read = rd_en && !empty;
    assign do_write = wr_en && has_free_space;
    assign read_last_element = (head == tail);
    assign do_read_and_write = do_read && do_write;
    
    integer i;
    
    // Buffer register update logic
    always @(posedge clk) begin
        // First stage buffers
        for(i=0; i<SIZE; i=i+1) begin
            mem_data_buf1[i] <= mem_data[i];
            mem_next_buf1[i] <= mem_next[i];
        end
        head_buf1 <= head;
        free_ptr_buf1 <= free_ptr;
        read_last_element_buf <= read_last_element;
        
        // Second stage buffers
        for(i=0; i<SIZE; i=i+1) begin
            mem_data_buf2[i] <= mem_data_buf1[i];
            mem_next_buf2[i] <= mem_next_buf1[i];
        end
        head_buf2 <= head_buf1;
        free_ptr_buf2 <= free_ptr_buf1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Reset state
            head <= 0;
            tail <= 0;
            free_ptr <= 1;
            dout <= {DW{1'b0}};
            
            // Initialize linked list
            for(i=0; i<SIZE; i=i+1) begin
                mem_next[i] <= (i < SIZE-1) ? i+1 : 0;
            end
        end
        else if(do_read_and_write) begin
            // Combined read and write operation - highest priority
            mem_data[free_ptr_buf1] <= din;
            dout <= mem_data_buf1[head_buf1];
            mem_next[head_buf1] <= free_ptr_buf1;
            
            // Update pointers
            tail <= free_ptr_buf1;
            free_ptr <= read_last_element_buf ? mem_next_buf2[free_ptr_buf1] : head_buf1;
            head <= read_last_element_buf ? 0 : mem_next_buf2[head_buf1];
        end
        else if(do_write) begin
            // Write-only operation
            mem_data[free_ptr_buf1] <= din;
            tail <= free_ptr_buf1;
            free_ptr <= mem_next_buf2[free_ptr_buf1];
        end
        else if(do_read) begin
            // Read-only operation
            dout <= mem_data_buf1[head_buf1];
            mem_next[head_buf1] <= free_ptr_buf1;
            free_ptr <= head_buf1;
            head <= read_last_element_buf ? 0 : mem_next_buf2[head_buf1];
        end
    end
endmodule