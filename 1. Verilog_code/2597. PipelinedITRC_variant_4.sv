//SystemVerilog
module PipelinedITRC #(parameter WIDTH=8) (
    input wire clk, reset,
    input wire [WIDTH-1:0] irq_inputs,
    output reg irq_valid,
    output reg [2:0] irq_vector
);

    // Pipeline stage registers
    reg [WIDTH-1:0] irq_capture_reg;
    reg [WIDTH-1:0] irq_priority_reg;
    reg [WIDTH-1:0] irq_output_reg;
    
    reg capture_valid;
    reg priority_valid;
    reg output_valid;
    
    reg [2:0] priority_vector;
    reg [2:0] output_vector;

    // Stage 1: Input Capture
    always @(posedge clk) begin
        if (reset) begin
            irq_capture_reg <= 0;
            capture_valid <= 0;
        end else begin
            irq_capture_reg <= irq_inputs;
            capture_valid <= |irq_inputs;
        end
    end

    // Stage 2: Priority Encoding
    always @(posedge clk) begin
        if (reset) begin
            irq_priority_reg <= 0;
            priority_valid <= 0;
            priority_vector <= 0;
        end else begin
            irq_priority_reg <= irq_capture_reg;
            priority_valid <= capture_valid;
            
            casex (irq_capture_reg)
                8'b1xxxxxxx: priority_vector <= 7;
                8'b01xxxxxx: priority_vector <= 6;
                8'b001xxxxx: priority_vector <= 5;
                8'b0001xxxx: priority_vector <= 4;
                8'b00001xxx: priority_vector <= 3;
                8'b000001xx: priority_vector <= 2;
                8'b0000001x: priority_vector <= 1;
                8'b00000001: priority_vector <= 0;
                default: priority_vector <= 0;
            endcase
        end
    end

    // Stage 3: Output Generation
    always @(posedge clk) begin
        if (reset) begin
            irq_output_reg <= 0;
            output_valid <= 0;
            output_vector <= 0;
            irq_valid <= 0;
            irq_vector <= 0;
        end else begin
            irq_output_reg <= irq_priority_reg;
            output_valid <= priority_valid;
            output_vector <= priority_vector;
            
            irq_valid <= output_valid;
            irq_vector <= output_vector;
        end
    end

endmodule