//SystemVerilog
module PriorityITRC #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] irq_in,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);

    // Stage 1: Input and Priority Detection
    reg [WIDTH-1:0] irq_in_stage1;
    reg enable_stage1;
    reg [$clog2(WIDTH)-1:0] irq_id_stage1;
    reg found_stage1;
    reg irq_valid_stage1;
    
    // Stage 2: Acknowledge Generation
    reg [WIDTH-1:0] irq_ack_stage2;
    reg [$clog2(WIDTH)-1:0] irq_id_stage2;
    reg irq_valid_stage2;

    // Stage 1: Input Register
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_in_stage1 <= 0;
            enable_stage1 <= 0;
        end else begin
            irq_in_stage1 <= irq_in;
            enable_stage1 <= enable;
        end
    end

    // Stage 1: Priority Detection
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_id_stage1 <= 0;
            found_stage1 <= 0;
            irq_valid_stage1 <= 0;
        end else begin
            irq_valid_stage1 <= |irq_in;
            found_stage1 <= 0;
            
            for (integer i = WIDTH-1; i >= 0; i=i-1) begin
                if (irq_in[i] && !found_stage1) begin
                    irq_id_stage1 <= i[$clog2(WIDTH)-1:0];
                    found_stage1 <= 1;
                end
            end
        end
    end
    
    // Stage 2: Acknowledge Generation
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_ack_stage2 <= 0;
            irq_id_stage2 <= 0;
            irq_valid_stage2 <= 0;
        end else if (enable_stage1) begin
            irq_ack_stage2 <= 0;
            irq_id_stage2 <= irq_id_stage1;
            irq_valid_stage2 <= irq_valid_stage1;
            
            if (irq_valid_stage1) begin
                irq_ack_stage2[irq_id_stage1] <= 1;
            end
        end
    end
    
    // Output Register
    always @(posedge clk) begin
        if (!rst_n) begin
            irq_ack <= 0;
            irq_id <= 0;
            irq_valid <= 0;
        end else begin
            irq_ack <= irq_ack_stage2;
            irq_id <= irq_id_stage2;
            irq_valid <= irq_valid_stage2;
        end
    end
    
endmodule