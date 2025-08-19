//SystemVerilog
module FifoITRC #(parameter DEPTH=4, WIDTH=3) (
    input wire clk, rst_n,
    input wire [7:0] irq_in,
    input wire irq_ack,
    output reg irq_out,
    output reg [WIDTH-1:0] irq_id
);
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [1:0] head, tail;
    reg [2:0] count;
    
    // Buffer registers for high fanout signals
    reg [7:0] irq_in_buf;
    reg [WIDTH-1:0] fifo_buf [0:DEPTH-1];
    reg [1:0] head_buf, tail_buf;
    reg [2:0] count_buf;
    reg irq_out_buf;
    reg [WIDTH-1:0] irq_id_buf;
    
    // Additional buffer registers for fanout optimization
    reg [7:0] irq_in_buf2;
    reg [1:0] head_buf2, tail_buf2;
    reg [2:0] count_buf2;
    reg irq_out_buf2;
    reg [WIDTH-1:0] irq_id_buf2;
    
    // First stage: Buffer input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_in_buf <= 8'b0;
            irq_in_buf2 <= 8'b0;
        end else begin
            irq_in_buf <= irq_in;
            irq_in_buf2 <= irq_in_buf;
        end
    end
    
    // Second stage: Main logic with buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0; tail <= 0; count <= 0;
            irq_out <= 0; irq_id <= 0;
            head_buf <= 0; tail_buf <= 0; count_buf <= 0;
            irq_out_buf <= 0; irq_id_buf <= 0;
            head_buf2 <= 0; tail_buf2 <= 0; count_buf2 <= 0;
            irq_out_buf2 <= 0; irq_id_buf2 <= 0;
        end else begin
            // Process new interrupts with buffered signals
            if (irq_in_buf2[0] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 0;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[1] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 1;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[2] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 2;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[3] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 3;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[4] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 4;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[5] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 5;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[6] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 6;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            else if (irq_in_buf2[7] && count_buf2 < DEPTH) begin
                fifo[tail_buf2] <= 7;
                tail_buf2 <= (tail_buf2 == DEPTH-1) ? 0 : tail_buf2 + 1;
                count_buf2 <= count_buf2 + 1;
            end
            
            // Handle current interrupt with buffered signals
            if (count_buf2 > 0 && !irq_out_buf2) begin
                irq_id_buf2 <= fifo[head_buf2];
                irq_out_buf2 <= 1;
            end
            
            // Acknowledge current interrupt with buffered signals
            if (irq_ack && irq_out_buf2) begin
                head_buf2 <= (head_buf2 == DEPTH-1) ? 0 : head_buf2 + 1;
                count_buf2 <= count_buf2 - 1;
                irq_out_buf2 <= (count_buf2 > 1);
                
                if (count_buf2 > 1) begin
                    if (head_buf2 == DEPTH-1)
                        irq_id_buf2 <= fifo[0];
                    else if (head_buf2 == 0)
                        irq_id_buf2 <= fifo[1];
                    else if (head_buf2 == 1)
                        irq_id_buf2 <= fifo[2];
                    else if (head_buf2 == 2)
                        irq_id_buf2 <= fifo[3];
                end
            end
            
            // Update intermediate buffers
            head_buf <= head_buf2;
            tail_buf <= tail_buf2;
            count_buf <= count_buf2;
            irq_out_buf <= irq_out_buf2;
            irq_id_buf <= irq_id_buf2;
            
            // Final stage: Update output registers
            head <= head_buf;
            tail <= tail_buf;
            count <= count_buf;
            irq_out <= irq_out_buf;
            irq_id <= irq_id_buf;
        end
    end
endmodule