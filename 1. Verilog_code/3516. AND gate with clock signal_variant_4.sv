//SystemVerilog
//IEEE 1364-2005 Verilog
// Pipelined AND gate with req/ack handshaking
// Enhanced pipeline depth for higher maximum frequency
module and_gate_clock (
    input wire clk,            // Clock signal
    input wire rst_n,          // Active low reset
    input wire a_in,           // Input A
    input wire b_in,           // Input B
    input wire req_in,         // Input request signal (was valid_in)
    output reg ack_out,        // Acknowledge input received (was ready_out)
    output reg y_out,          // Output Y
    output reg req_out         // Output request signal (was valid_out)
);

    // Pipeline stage 1 - Input registration
    reg a_stage1, b_stage1;
    reg req_stage1;
    
    // Pipeline stage 2 - Input processing
    reg a_stage2, b_stage2;
    reg req_stage2;
    
    // Pipeline stage 3 - Pre-compute
    reg a_stage3, b_stage3;
    reg req_stage3;
    
    // Pipeline stage 4 - AND operation
    reg result_stage4;
    reg req_stage4;
    
    // Pipeline stage 5 - Result preparation
    reg result_stage5;
    reg req_stage5;
    
    // Flow control signals
    reg pipeline_ready;

    // Acknowledge signal generation - only acknowledge when pipeline is ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack_out <= 1'b0;
            pipeline_ready <= 1'b1;
        end else begin
            if (req_in && pipeline_ready) begin
                ack_out <= 1'b1;
            end else begin
                ack_out <= 1'b0;
            end
            
            // Pipeline is always ready in this implementation
            pipeline_ready <= 1'b1;
        end
    end

    // Pipeline stage 1 - Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            req_stage1 <= 1'b0;
        end else begin
            if (req_in && pipeline_ready) begin
                a_stage1 <= a_in;
                b_stage1 <= b_in;
                req_stage1 <= 1'b1;
            end else if (!req_in) begin
                req_stage1 <= 1'b0;
            end
        end
    end

    // Pipeline stage 2 - Input processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
            req_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            req_stage2 <= req_stage1;
        end
    end
    
    // Pipeline stage 3 - Pre-compute
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage3 <= 1'b0;
            b_stage3 <= 1'b0;
            req_stage3 <= 1'b0;
        end else begin
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
            req_stage3 <= req_stage2;
        end
    end

    // Pipeline stage 4 - Perform AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage4 <= 1'b0;
            req_stage4 <= 1'b0;
        end else begin
            result_stage4 <= a_stage3 & b_stage3;
            req_stage4 <= req_stage3;
        end
    end
    
    // Pipeline stage 5 - Result preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage5 <= 1'b0;
            req_stage5 <= 1'b0;
        end else begin
            result_stage5 <= result_stage4;
            req_stage5 <= req_stage4;
        end
    end

    // Final output stage - Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= 1'b0;
            req_out <= 1'b0;
        end else begin
            y_out <= result_stage5;
            req_out <= req_stage5;
        end
    end

endmodule