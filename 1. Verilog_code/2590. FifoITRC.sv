module FifoITRC #(parameter DEPTH=4, WIDTH=3) (
    input wire clk, rst_n,
    input wire [7:0] irq_in,
    input wire irq_ack,
    output reg irq_out,
    output reg [WIDTH-1:0] irq_id
);
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [1:0] head, tail; // For DEPTH=4, we need 2 bits
    reg [2:0] count; // Needs one extra bit for comparison
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0; tail <= 0; count <= 0;
            irq_out <= 0; irq_id <= 0;
        end else begin
            // Process new interrupts sequentially instead of using a loop
            if (irq_in[0] && count < DEPTH) begin
                fifo[tail] <= 0;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[1] && count < DEPTH) begin
                fifo[tail] <= 1;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[2] && count < DEPTH) begin
                fifo[tail] <= 2;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[3] && count < DEPTH) begin
                fifo[tail] <= 3;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[4] && count < DEPTH) begin
                fifo[tail] <= 4;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[5] && count < DEPTH) begin
                fifo[tail] <= 5;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[6] && count < DEPTH) begin
                fifo[tail] <= 6;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            else if (irq_in[7] && count < DEPTH) begin
                fifo[tail] <= 7;
                tail <= (tail == DEPTH-1) ? 0 : tail + 1;
                count <= count + 1;
            end
            
            // Handle current interrupt
            if (count > 0 && !irq_out) begin
                irq_id <= fifo[head];
                irq_out <= 1;
            end
            
            // Acknowledge current interrupt
            if (irq_ack && irq_out) begin
                head <= (head == DEPTH-1) ? 0 : head + 1;
                count <= count - 1;
                irq_out <= (count > 1);
                
                // Handle next interrupt output (without variable indexing)
                if (count > 1) begin
                    if (head == DEPTH-1)
                        irq_id <= fifo[0];
                    else if (head == 0)
                        irq_id <= fifo[1];
                    else if (head == 1)
                        irq_id <= fifo[2];
                    else if (head == 2)
                        irq_id <= fifo[3];
                end
            end
        end
    end
endmodule