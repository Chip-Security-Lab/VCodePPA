//SystemVerilog
module delayed_output_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out,
    output reg req,
    input wire ack
);
    // Internal signals - moved some registers after combinational logic
    reg [7:0] buffer_stage2;
    reg req_pending_stage1, req_pending_stage2;
    reg load_stage2;
    reg req_stage1;
    reg ack_stage1;
    wire req_pending_next;
    
    // Combinational logic moved before registers
    assign req_pending_next = load ? 1'b1 : 
                             (req_stage1 && ack_stage1) ? 1'b0 : req_pending_stage1;
    
    // Modified stage 1: Register after combinational logic
    always @(posedge clk) begin
        if (rst) begin
            req_pending_stage1 <= 1'b0;
            ack_stage1 <= 1'b0;
        end else begin
            req_pending_stage1 <= req_pending_next;
            ack_stage1 <= ack;
        end
    end
    
    // Request generation in stage 1
    always @(posedge clk) begin
        if (rst) begin
            req_stage1 <= 1'b0;
        end else begin
            if (req_pending_stage1 && !req_stage1)
                req_stage1 <= 1'b1;
            else if (req_stage1 && ack_stage1)
                req_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2: Capturing data directly from input
    always @(posedge clk) begin
        if (rst) begin
            buffer_stage2 <= 8'b0;
            req_pending_stage2 <= 1'b0;
            load_stage2 <= 1'b0;
            req <= 1'b0;
        end else begin
            // Data path now directly from input when load is active
            buffer_stage2 <= load ? data_in : buffer_stage2;
            req_pending_stage2 <= req_pending_stage1;
            load_stage2 <= load;
            req <= req_stage1;
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
        end else begin
            data_out <= buffer_stage2;
        end
    end
endmodule