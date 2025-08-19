//SystemVerilog
module AdaptiveITRC #(parameter WIDTH=4) (
    input wire clk, rst,
    input wire [WIDTH-1:0] irq_in,
    input wire ack,
    output reg irq_out,
    output reg [1:0] irq_id
);

    // Stage 1: Update occurrence counts
    reg [3:0] occurrence_count [0:WIDTH-1];
    reg [WIDTH-1:0] irq_in_stage1;
    reg valid_stage1;
    
    // Stage 2: Priority encoding and max count finding
    reg [3:0] occurrence_count_stage2 [0:WIDTH-1];
    reg [WIDTH-1:0] irq_in_stage2;
    reg [1:0] priority_order_stage2 [0:WIDTH-1];
    reg valid_stage2;
    reg [3:0] max_count_stage2;
    reg [1:0] max_idx_stage2;
    
    // Stage 3: Priority update and output generation
    reg [1:0] priority_order [0:WIDTH-1];
    reg valid_stage3;
    reg [3:0] max_count_stage3;
    reg [1:0] max_idx_stage3;
    
    integer i;
    
    // Initialize priority order
    initial begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            priority_order[i] = i;
        end
    end

    // Stage 1: Update occurrence counts
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count[i] <= 0;
            end
        end else begin
            valid_stage1 <= 1;
            irq_in_stage1 <= irq_in;
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count[i] <= occurrence_count[i] + irq_in[i];
            end
        end
    end

    // Stage 2: Priority encoding and max count finding
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                priority_order_stage2[i] <= i;
            end
        end else begin
            valid_stage2 <= valid_stage1;
            irq_in_stage2 <= irq_in_stage1;
            for (i = 0; i < WIDTH; i = i + 1) begin
                occurrence_count_stage2[i] <= occurrence_count[i];
                priority_order_stage2[i] <= priority_order[i];
            end
            
            // Find max count using parallel comparison
            max_count_stage2 = occurrence_count[0];
            max_idx_stage2 = 0;
            for (i = 1; i < WIDTH; i = i + 1) begin
                if (occurrence_count[i] > max_count_stage2) begin
                    max_count_stage2 = occurrence_count[i];
                    max_idx_stage2 = i;
                end
            end
        end
    end

    // Stage 3: Priority update and output generation
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 0;
            irq_out <= 0;
            irq_id <= 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                priority_order[i] <= i;
            end
        end else begin
            valid_stage3 <= valid_stage2;
            max_count_stage3 <= max_count_stage2;
            max_idx_stage3 <= max_idx_stage2;
            
            // Update priority order using shift register
            priority_order[0] <= max_idx_stage2;
            for (i = 1; i < WIDTH; i = i + 1) begin
                priority_order[i] <= priority_order_stage2[i-1];
            end
            
            // Generate output using priority encoder
            if (irq_in_stage2[0]) begin
                irq_id <= priority_order_stage2[0];
            end else if (irq_in_stage2[1]) begin
                irq_id <= priority_order_stage2[1];
            end else if (irq_in_stage2[2]) begin
                irq_id <= priority_order_stage2[2];
            end else if (irq_in_stage2[3]) begin
                irq_id <= priority_order_stage2[3];
            end else begin
                irq_id <= 0;
            end
            
            irq_out <= |irq_in_stage2;
            
            // Clear output on acknowledge
            if (ack) begin
                irq_out <= 0;
            end
        end
    end
endmodule