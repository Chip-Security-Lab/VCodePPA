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
    
    // Reset logic in separate always block
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            head <= 0;
            tail <= 0;
            free_ptr <= 1;
        end
    end
    
    // Initialize mem_next array on reset
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<SIZE; i=i+1) begin
                if(i < SIZE-1)
                    mem_next[i] <= i+1;
                else
                    mem_next[i] <= 0;
            end
        end
    end
    
    // Write operation logic
    always @(posedge clk) begin
        if(rst_n && wr_en && free_ptr != 0) begin
            mem_data[free_ptr] <= din;
            tail <= free_ptr;
            free_ptr <= mem_next[free_ptr];
        end
    end
    
    // Read operation logic
    always @(posedge clk) begin
        if(rst_n && rd_en && head != 0) begin
            dout <= mem_data[head];
            mem_next[head] <= free_ptr;
            free_ptr <= head;
            head <= (head == tail) ? 0 : mem_next[head];
        end
    end
endmodule