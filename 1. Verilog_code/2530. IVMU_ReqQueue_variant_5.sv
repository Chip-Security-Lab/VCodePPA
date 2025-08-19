//SystemVerilog
module IVMU_ReqQueue_Pipelined #(parameter DEPTH=4) (
    input clk,
    input reset_n, // Active low reset
    input rd_en,
    input [7:0] irq,
    output [7:0] next_irq
);

    // Stage 2 State Registers: Stores the main queue state
    reg [7:0] queue_reg_s2 [0:DEPTH-1];

    // Stage 1 Output Registers: Stores the calculated next state from Stage 1
    reg [7:0] next_queue_reg_s1 [0:DEPTH-1];

    // Stage 2 Output Register: Stores the final output
    reg [7:0] next_irq_reg_s2;

    integer i;

    // Stage 1: Combinational logic to calculate the next queue state
    wire [7:0] next_queue_calc_s1 [0:DEPTH-1];

    generate
        genvar j;
        for (j = 0; j < DEPTH; j = j + 1) begin : next_q_calc_gen
            assign next_queue_calc_s1[j] = rd_en ?
                                        (j == DEPTH-1 ? 8'h0 : queue_reg_s2[j+1]) : // Shift left (read)
                                        (j == 0 ? irq : queue_reg_s2[j-1]);          // Shift right (write)
        end
    endgenerate

    // Stage 1 Registers: Latch the calculated next state
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                next_queue_reg_s1[i] <= 8'h0; // Reset intermediate state
            end
        end else begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                next_queue_reg_s1[i] <= next_queue_calc_s1[i];
            end
        end
    end

    // Stage 2 Registers: Update the main queue state and the output
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                queue_reg_s2[i] <= 8'h0; // Reset queue state
            end
            next_irq_reg_s2 <= 8'h0;     // Reset output
        end else begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                queue_reg_s2[i] <= next_queue_reg_s1[i];
            end
            // Output is the head of the state computed in Stage 1, registered in Stage 2
            next_irq_reg_s2 <= next_queue_reg_s1[0];
        end
    end

    // Connect the final registered output
    assign next_irq = next_irq_reg_s2;

endmodule