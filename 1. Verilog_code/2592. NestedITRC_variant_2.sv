//SystemVerilog
module NestedITRC #(parameter DEPTH=2) (
    input wire clk, reset,
    input wire [7:0] irq_sources,
    input wire push, pop,
    output reg current_irq_valid,
    output reg [2:0] current_irq_id
);
    // Buffered high fanout signals
    reg [2:0] irq_stack [0:DEPTH-1];
    reg [1:0] stack_ptr;
    reg [1:0] stack_ptr_buf;
    reg [2:0] priority_encoder;
    reg [2:0] priority_encoder_buf;
    reg [7:0] irq_sources_buf;
    
    // Priority encoder logic with buffering
    always @(posedge clk) begin
        if (reset) begin
            irq_sources_buf <= 8'b0;
        end else begin
            irq_sources_buf <= irq_sources;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            priority_encoder <= 3'd0;
        end else begin
            priority_encoder <= irq_sources_buf[7] ? 3'd7 :
                              irq_sources_buf[6] ? 3'd6 :
                              irq_sources_buf[5] ? 3'd5 :
                              irq_sources_buf[4] ? 3'd4 :
                              irq_sources_buf[3] ? 3'd3 :
                              irq_sources_buf[2] ? 3'd2 :
                              irq_sources_buf[1] ? 3'd1 :
                              irq_sources_buf[0] ? 3'd0 : 3'd0;
        end
    end
    
    // Buffer priority encoder output
    always @(posedge clk) begin
        if (reset) begin
            priority_encoder_buf <= 3'd0;
        end else begin
            priority_encoder_buf <= priority_encoder;
        end
    end
    
    // Buffer stack pointer
    always @(posedge clk) begin
        if (reset) begin
            stack_ptr_buf <= 2'd0;
        end else begin
            stack_ptr_buf <= stack_ptr;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            current_irq_valid <= 0;
            current_irq_id <= 0;
            irq_stack[0] <= 0;
            irq_stack[1] <= 0;
        end else begin
            case ({push, pop, |irq_sources_buf, stack_ptr_buf < DEPTH, stack_ptr_buf > 0})
                5'b10010: begin // push && |irq_sources && stack_ptr < DEPTH
                    irq_stack[stack_ptr_buf] <= priority_encoder_buf;
                    stack_ptr <= stack_ptr_buf + 1;
                    current_irq_valid <= 1;
                    current_irq_id <= priority_encoder_buf;
                end
                5'b01001: begin // pop && stack_ptr > 0
                    stack_ptr <= stack_ptr_buf - 1;
                    if (stack_ptr_buf > 1) begin
                        current_irq_id <= irq_stack[0];
                        current_irq_valid <= 1;
                    end else begin
                        current_irq_valid <= 0;
                    end
                end
                default: begin
                    // Maintain current state
                end
            endcase
        end
    end
endmodule