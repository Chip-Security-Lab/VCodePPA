//SystemVerilog
module AdaptiveITRC #(parameter WIDTH=4) (
    input wire clk, rst,
    input wire [WIDTH-1:0] irq_in,
    input wire ack,
    output reg irq_out,
    output reg [1:0] irq_id
);
    reg [3:0] occurrence_count [0:WIDTH-1];
    reg [1:0] priority_order [0:WIDTH-1];
    reg [3:0] occurrence_count_pipe [0:WIDTH-1];
    reg [1:0] priority_order_pipe [0:WIDTH-1];
    reg [WIDTH-1:0] irq_in_pipe;
    reg ack_pipe;
    
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    wire [WIDTH-1:0] sum_pipe;
    wire [WIDTH:0] carry_pipe;

    integer i;
    initial begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            occurrence_count[i] = 0;
            priority_order[i] = i;
            occurrence_count_pipe[i] = 0;
            priority_order_pipe[i] = i;
        end
    end

    // First stage pipeline
    generate
        genvar j;
        for (j = 0; j < WIDTH; j = j + 1) begin : cla_adder_stage1
            assign sum[j] = irq_in[j] ^ occurrence_count[j];
            assign carry[j+1] = (irq_in[j] & occurrence_count[j]) | (carry[j] & (irq_in[j] | occurrence_count[j]));
        end
    endgenerate

    // Second stage pipeline
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : cla_adder_stage2
            assign sum_pipe[j] = irq_in_pipe[j] ^ occurrence_count_pipe[j];
            assign carry_pipe[j+1] = (irq_in_pipe[j] & occurrence_count_pipe[j]) | (carry_pipe[j] & (irq_in_pipe[j] | occurrence_count_pipe[j]));
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            irq_out <= 0;
            irq_id <= 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count[i] <= 0;
                priority_order[i] <= i;
                occurrence_count_pipe[i] <= 0;
                priority_order_pipe[i] <= i;
            end
        end else begin
            // Pipeline stage 1
            irq_in_pipe <= irq_in;
            ack_pipe <= ack;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (irq_in[i]) 
                    occurrence_count_pipe[i] <= occurrence_count[i] + 1;
                else
                    occurrence_count_pipe[i] <= occurrence_count[i];
            end
            
            // Pipeline stage 2
            irq_out <= 0;
            if (irq_in_pipe[priority_order_pipe[0]]) begin
                irq_out <= 1;
                irq_id <= priority_order_pipe[0];
            end else if (irq_in_pipe[priority_order_pipe[1]]) begin
                irq_out <= 1;
                irq_id <= priority_order_pipe[1];
            end else if (irq_in_pipe[priority_order_pipe[2]]) begin
                irq_out <= 1;
                irq_id <= priority_order_pipe[2];
            end else if (irq_in_pipe[priority_order_pipe[3]]) begin
                irq_out <= 1;
                irq_id <= priority_order_pipe[3];
            end
            
            // Priority update logic
            if (occurrence_count_pipe[0] > occurrence_count_pipe[1] && 
                occurrence_count_pipe[0] > occurrence_count_pipe[2] && 
                occurrence_count_pipe[0] > occurrence_count_pipe[3]) begin
                priority_order[0] <= 0;
            end else if (occurrence_count_pipe[1] > occurrence_count_pipe[0] && 
                        occurrence_count_pipe[1] > occurrence_count_pipe[2] && 
                        occurrence_count_pipe[1] > occurrence_count_pipe[3]) begin
                priority_order[0] <= 1;
            end else if (occurrence_count_pipe[2] > occurrence_count_pipe[0] && 
                        occurrence_count_pipe[2] > occurrence_count_pipe[1] && 
                        occurrence_count_pipe[2] > occurrence_count_pipe[3]) begin
                priority_order[0] <= 2;
            end else if (occurrence_count_pipe[3] > occurrence_count_pipe[0] && 
                        occurrence_count_pipe[3] > occurrence_count_pipe[1] && 
                        occurrence_count_pipe[3] > occurrence_count_pipe[2]) begin
                priority_order[0] <= 3;
            end
            
            // Update pipeline registers
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count[i] <= occurrence_count_pipe[i];
                priority_order[i] <= priority_order_pipe[i];
            end
            
            if (ack_pipe) irq_out <= 0;
        end
    end
endmodule