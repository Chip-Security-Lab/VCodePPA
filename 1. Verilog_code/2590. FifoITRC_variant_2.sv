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
    wire [7:0] irq_valid;
    wire fifo_full;
    wire fifo_empty;

    assign fifo_full = (count == DEPTH);
    assign fifo_empty = (count == 0);
    assign irq_valid = irq_in & {8{~fifo_full}};

    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            irq_out <= 0;
            irq_id <= 0;
        end
    end

    // Pre-registered control signals
    reg [7:0] irq_valid_reg;
    reg fifo_empty_reg;
    reg [2:0] count_reg;
    reg [1:0] head_reg, tail_reg;

    always @(posedge clk) begin
        if (rst_n) begin
            irq_valid_reg <= irq_valid;
            fifo_empty_reg <= fifo_empty;
            count_reg <= count;
            head_reg <= head;
            tail_reg <= tail;
        end
    end

    // FIFO write logic with optimized pipeline
    reg [WIDTH-1:0] fifo_stage1;
    reg [1:0] tail_stage1;
    reg [2:0] count_stage1;

    always @(posedge clk) begin
        if (rst_n) begin
            if (irq_valid_reg[0]) fifo_stage1 <= 0;
            else if (irq_valid_reg[1]) fifo_stage1 <= 1;
            else if (irq_valid_reg[2]) fifo_stage1 <= 2;
            else if (irq_valid_reg[3]) fifo_stage1 <= 3;
            else if (irq_valid_reg[4]) fifo_stage1 <= 4;
            else if (irq_valid_reg[5]) fifo_stage1 <= 5;
            else if (irq_valid_reg[6]) fifo_stage1 <= 6;
            else if (irq_valid_reg[7]) fifo_stage1 <= 7;
            else fifo_stage1 <= fifo[tail_reg];

            tail_stage1 <= (tail_reg == DEPTH-1) ? 0 : tail_reg + 1;
            count_stage1 <= count_reg + 1;
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            fifo[tail_stage1] <= fifo_stage1;
            tail <= tail_stage1;
            count <= count_stage1;
        end
    end

    // Pre-registered interrupt output signals
    reg [WIDTH-1:0] next_irq_id;
    reg next_irq_out;

    always @(posedge clk) begin
        if (rst_n) begin
            if (!fifo_empty_reg && !irq_out) begin
                next_irq_id <= fifo[head_reg];
                next_irq_out <= 1;
            end
        end
    end

    // Output stage with optimized timing
    always @(posedge clk) begin
        if (rst_n) begin
            if (next_irq_out) begin
                irq_id <= next_irq_id;
                irq_out <= 1;
            end
        end
    end

    // Pre-registered acknowledge signals
    reg irq_ack_reg;
    reg [1:0] next_head;
    reg [2:0] next_count;
    reg next_irq_out_ack;

    always @(posedge clk) begin
        if (rst_n) begin
            irq_ack_reg <= irq_ack;
            if (irq_ack_reg && irq_out) begin
                next_head <= (head == DEPTH-1) ? 0 : head + 1;
                next_count <= count - 1;
                next_irq_out_ack <= (count > 1);
            end
        end
    end

    // Acknowledge stage with optimized timing
    always @(posedge clk) begin
        if (rst_n) begin
            if (irq_ack_reg && irq_out) begin
                head <= next_head;
                count <= next_count;
                irq_out <= next_irq_out_ack;
                
                if (next_count > 1) begin
                    case(next_head)
                        0: irq_id <= fifo[1];
                        1: irq_id <= fifo[2];
                        2: irq_id <= fifo[3];
                        3: irq_id <= fifo[0];
                    endcase
                end
            end
        end
    end
endmodule