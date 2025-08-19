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
    
    wire [WIDTH-1:0] next_irq_id;
    wire [1:0] next_head, next_tail;
    wire [2:0] next_count;
    wire next_irq_out;
    
    // Priority encoder for irq_in
    wire [2:0] irq_priority;
    wire irq_valid;
    
    assign irq_valid = |irq_in;
    assign irq_priority = irq_in[0] ? 3'd0 :
                         irq_in[1] ? 3'd1 :
                         irq_in[2] ? 3'd2 :
                         irq_in[3] ? 3'd3 :
                         irq_in[4] ? 3'd4 :
                         irq_in[5] ? 3'd5 :
                         irq_in[6] ? 3'd6 :
                         irq_in[7] ? 3'd7 : 3'd0;
    
    // Parallel prefix subtractor for count
    wire [2:0] count_pp;
    wire [2:0] count_pp_prop;
    wire [2:0] count_pp_gen;
    
    // Generate and propagate signals
    assign count_pp_gen = (irq_valid && count < DEPTH) ? 3'b001 : 
                         (irq_ack && irq_out) ? 3'b111 : 3'b000;
    assign count_pp_prop = (irq_valid && count < DEPTH) ? 3'b000 : 
                          (irq_ack && irq_out) ? 3'b000 : 3'b111;
    
    // Parallel prefix tree
    wire [2:0] pp_stage1 [0:1];
    wire [2:0] pp_stage2 [0:0];
    
    // Stage 1
    assign pp_stage1[0] = count_pp_gen[0] ? 3'b001 : 
                         (count_pp_prop[0] ? count_pp_gen[1] : 3'b000);
    assign pp_stage1[1] = count_pp_gen[1] ? 3'b010 : 
                         (count_pp_prop[1] ? count_pp_gen[2] : 3'b000);
    
    // Stage 2
    assign pp_stage2[0] = pp_stage1[0] | (count_pp_prop[0] ? pp_stage1[1] : 3'b000);
    
    // Final count update
    assign count_pp = (!rst_n) ? 3'd0 : 
                     (count + pp_stage2[0]);
    
    // Next state logic
    assign next_tail = (!rst_n) ? 2'd0 :
                      (irq_valid && count < DEPTH) ? ((tail == DEPTH-1) ? 2'd0 : tail + 1'd1) :
                      tail;
                      
    assign next_head = (!rst_n) ? 2'd0 :
                      (irq_ack && irq_out) ? ((head == DEPTH-1) ? 2'd0 : head + 1'd1) :
                      head;
                      
    assign next_count = count_pp;
                       
    assign next_irq_out = (!rst_n) ? 1'b0 :
                         (count > 0 && !irq_out) ? 1'b1 :
                         (irq_ack && irq_out) ? (count > 1) :
                         irq_out;
                         
    assign next_irq_id = (!rst_n) ? {WIDTH{1'b0}} :
                        (count > 0 && !irq_out) ? fifo[head] :
                        (irq_ack && irq_out && count > 1) ? 
                            ((head == DEPTH-1) ? fifo[0] :
                             (head == 0) ? fifo[1] :
                             (head == 1) ? fifo[2] :
                             fifo[3]) :
                        irq_id;
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            irq_out <= 0;
            irq_id <= 0;
        end else begin
            head <= next_head;
            tail <= next_tail;
            count <= next_count;
            irq_out <= next_irq_out;
            irq_id <= next_irq_id;
            
            // Write to FIFO
            if (irq_valid && count < DEPTH) begin
                fifo[tail] <= irq_priority;
            end
        end
    end
endmodule